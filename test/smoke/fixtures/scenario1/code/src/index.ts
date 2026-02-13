import { Command } from 'commander';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function getVersion(): string {
    try {
        const pkgPath = join(__dirname, '..', 'package.json');
        const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
        return pkg.version ?? '0.0.0';
    } catch {
        return '0.0.0';
    }
}

const program = new Command();

program
    .name('hello')
    .description('Simple Hello CLI for RW smoke test')
    .version(getVersion());

program
    .command('greet')
    .description('Greet someone by name')
    .argument('<name>', 'Name of the person to greet')
    .action((name: string) => {
        console.log(`Hello, ${name}!`);
    });

program.parse();
