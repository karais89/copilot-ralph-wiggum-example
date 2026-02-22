import fs from "fs/promises";
import path from "path";
import { loadTodos } from "../storage/json-store.js";
import { Todo } from "../models/todo.js";

function escapeField(value: string): string {
  if (value.includes(",") || value.includes("\n") || value.includes('"')) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

function todoToCsvRow(todo: Todo): string {
  return [
    escapeField(todo.id),
    escapeField(todo.title),
    escapeField(String(todo.completed)),
    escapeField(todo.createdAt),
  ].join(",");
}

export async function exportCommand(outputPath: string): Promise<void> {
  const todos = await loadTodos();

  const header = "id,title,completed,createdAt";
  const rows = [header, ...todos.map(todoToCsvRow)];
  const csvContent = rows.join("\n");

  const resolvedPath = path.resolve(outputPath);
  const dir = path.dirname(resolvedPath);

  try {
    await fs.access(dir);
  } catch {
    console.error(`Error: Directory does not exist: ${dir}`);
    process.exit(1);
  }

  try {
    await fs.writeFile(resolvedPath, csvContent, "utf-8");
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code === "EACCES" || code === "EPERM") {
      console.error(`Error: Permission denied: ${outputPath}`);
      process.exit(1);
    }
    throw error;
  }

  if (todos.length === 0) {
    console.log("⚠ No todos found. Created empty CSV.");
  } else {
    console.log(`✔ Exported ${todos.length} todo(s) to ${outputPath}`);
  }
}
