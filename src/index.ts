#!/usr/bin/env node

import { Command } from "commander";
import { addCommand } from "./commands/add.js";
import { listCommand } from "./commands/list.js";
import { doneCommand } from "./commands/update.js";
import { deleteCommand } from "./commands/delete.js";

const program = new Command();

program
  .name("todo")
  .version("1.0.0")
  .description("A command-line Todo application");

// Add command: todo add <title>
program
  .command("add <title>")
  .description("Add a new todo")
  .action(async (title: string) => {
    try {
      await addCommand(title);
    } catch (error) {
      console.error(`Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

// List command: todo list
program
  .command("list")
  .description("List all todos")
  .action(async () => {
    try {
      await listCommand();
    } catch (error) {
      console.error(`Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

// Done command: todo done <id>
program
  .command("done <id>")
  .description("Mark a todo as completed")
  .action(async (id: string) => {
    try {
      await doneCommand(id);
    } catch (error) {
      console.error(`Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

// Delete command: todo delete <id>
program
  .command("delete <id>")
  .description("Delete a todo")
  .action(async (id: string) => {
    try {
      await deleteCommand(id);
    } catch (error) {
      console.error(`Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

program.parse();
