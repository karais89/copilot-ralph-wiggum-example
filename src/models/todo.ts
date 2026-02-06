import { nanoid } from "nanoid";

/**
 * Represents a single Todo item.
 */
export interface Todo {
  id: string;
  title: string;
  completed: boolean;
  createdAt: string;
}

/**
 * Creates a new Todo with auto-generated id and createdAt timestamp.
 */
export function createTodo(title: string): Todo {
  return {
    id: nanoid(10),
    title,
    completed: false,
    createdAt: new Date().toISOString(),
  };
}
