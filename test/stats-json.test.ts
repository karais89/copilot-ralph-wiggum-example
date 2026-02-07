import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// Mock the storage layer used by the stats command. Note: stats.ts imports ../storage/json-store.js
vi.mock("../src/storage/json-store.js", () => {
  return {
    loadTodos: vi.fn(),
  };
});

import { statsCommand } from "../src/commands/stats";
import { loadTodos } from "../src/storage/json-store";

const mockedLoad = loadTodos as unknown as ReturnType<typeof vi.fn> & { mockResolvedValue?: any; mockRejectedValue?: any };

describe("stats --json output", () => {
  let logSpy: any;

  beforeEach(() => {
    vi.resetAllMocks();
    logSpy = vi.spyOn(console, "log").mockImplementation(() => {});
  });

  afterEach(() => {
    logSpy.mockRestore();
  });

  it("emits valid JSON with correct keys for non-empty todo list", async () => {
    (loadTodos as any).mockResolvedValue([
      { id: "a1", title: "First", completed: true, createdAt: new Date().toISOString() },
      { id: "b2", title: "Second", completed: false, createdAt: new Date().toISOString() },
    ]);

    await statsCommand(true);

    expect(logSpy).toHaveBeenCalled();
    const printed = logSpy.mock.calls[0][0];
    const parsed = JSON.parse(printed);

    expect(parsed).toHaveProperty("total");
    expect(parsed).toHaveProperty("completed");
    expect(parsed).toHaveProperty("pending");
    expect(parsed).toHaveProperty("overdue");
    expect(parsed).toHaveProperty("completionRate");
    expect(parsed).toHaveProperty("generated_at");

    expect(parsed.total).toBe(2);
    expect(parsed.completed).toBe(1);
    expect(parsed.pending).toBe(1);
    expect(typeof parsed.completionRate).toBe("number");
  });

  it("handles empty todo list (total=0) and returns completionRate 0", async () => {
    (loadTodos as any).mockResolvedValue([]);

    await statsCommand(true);

    const printed = logSpy.mock.calls[0][0];
    const parsed = JSON.parse(printed);

    expect(parsed.total).toBe(0);
    expect(parsed.completed).toBe(0);
    expect(parsed.pending).toBe(0);
    expect(parsed.completionRate).toBe(0);
  });

  it("handles partial/malformed todo items gracefully", async () => {
    // Simulate a todo missing the `completed` field
    (loadTodos as any).mockResolvedValue([
      { id: "x1", title: "NoCompleted", createdAt: new Date().toISOString() } as any,
    ]);

    await statsCommand(true);

    const printed = logSpy.mock.calls[0][0];
    const parsed = JSON.parse(printed);

    expect(parsed.total).toBe(1);
    // missing `completed` should be treated as falsy → 0 completed
    expect(parsed.completed).toBe(0);
    expect(parsed.pending).toBe(1);
  });

  it("propagates internal errors (rejects) when storage fails", async () => {
    (loadTodos as any).mockRejectedValue(new Error("internal failure"));

    await expect(statsCommand(true)).rejects.toThrow("internal failure");
  });
});
