import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import { Todo } from "../models/todo.js";

// Get the directory of the current file to locate data directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Data file path: data/todos.json relative to project root
const DATA_DIR = path.join(__dirname, "../../data");
const TODOS_FILE = path.join(DATA_DIR, "todos.json");

/**
 * Ensures the data directory exists, creating it if necessary.
 */
async function ensureDataDir(): Promise<void> {
  try {
    await fs.mkdir(DATA_DIR, { recursive: true });
  } catch (error) {
    throw new Error(
      `Failed to create data directory: ${error instanceof Error ? error.message : String(error)}`
    );
  }
}

/**
 * Loads all todos from the JSON file.
 * Returns an empty array if the file doesn't exist yet.
 * Handles JSON parse errors gracefully.
 */
export async function loadTodos(): Promise<Todo[]> {
  try {
    await ensureDataDir();
    const data = await fs.readFile(TODOS_FILE, "utf-8");
    const todos: Todo[] = JSON.parse(data);
    return Array.isArray(todos) ? todos : [];
  } catch (error) {
    // File doesn't exist or is invalid JSON — return empty array
    if (
      error instanceof Error &&
      (error.message.includes("ENOENT") ||
        error.message.includes("Unexpected token"))
    ) {
      return [];
    }
    throw new Error(
      `Failed to load todos: ${error instanceof Error ? error.message : String(error)}`
    );
  }
}

/**
 * Saves todos array to the JSON file.
 */
export async function saveTodos(todos: Todo[]): Promise<void> {
  try {
    await ensureDataDir();
    const json = JSON.stringify(todos, null, 2);
    await fs.writeFile(TODOS_FILE, json, "utf-8");
  } catch (error) {
    throw new Error(
      `Failed to save todos: ${error instanceof Error ? error.message : String(error)}`
    );
  }
}
