import { loadTodos } from "../storage/json-store.js";

/**
 * Handles the 'stats' command to display todo statistics.
 * @param json - If true, output as JSON; otherwise, output as formatted text
 */
export async function statsCommand(json: boolean = false): Promise<void> {
  try {
    // Load todos from storage
    const todos = await loadTodos();

    // Compute statistics
    const total = todos.length;
    const completed = todos.filter((todo) => todo.completed).length;
    const pending = total - completed;
    const completionRate = total === 0 ? 0 : Number(((completed / total) * 100).toFixed(2));
    // `overdue` is included in the JSON schema but the current Todo model
    // has no due date field; provide 0 as a sensible default for now.
    const overdue = 0;
    const generated_at = new Date().toISOString();

    // Output based on mode
    if (json) {
      // JSON output mode — include required schema fields
      const stats = {
        total,
        completed,
        pending,
        overdue,
        completionRate,
        generated_at,
      };
      console.log(JSON.stringify(stats, null, 2));
    } else {
      // Text output mode with visual formatting
      console.log("\n📊 Todo Statistics\n");
      console.log(`Total:      ${total}`);
      console.log(`Completed:  ${completed} ✓`);
      console.log(`Pending:    ${pending} ⏳`);
      console.log(`Progress:   ${completionRate}%\n`);
    }
  } catch (error) {
    if (error instanceof Error) {
      throw error;
    }
    throw new Error(`Failed to compute stats: ${String(error)}`);
  }
}
