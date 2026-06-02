# TypeScript Configuration

## TS 6.0+ New Defaults

TypeScript 6.0 (March 2026) changed several defaults for new projects:
- `strict: true` is now the default (was `false`)
- `module: "nodenext"` is now the default (was `"commonjs"`)
- `target: "es2025"` is now the default (was `"es3"`)
- `rootDir` is inferred from the `include` glob (was `.`)
- `isolatedDeclarations` is now stable (no longer experimental)

**Migration note**: Existing projects upgrading to TS 6.0 may need to explicitly set these if they relied on the old defaults. New projects benefit from the stricter defaults out of the box.

## TS 7.0 Beta (Go Compiler)

TypeScript 7.0 Beta (April 2026) is a full rewrite of the compiler in Go:
- ~10x faster type-checking and emit via `tsgo` CLI
- Shared-memory parallelism using goroutines
- Same `tsconfig.json` format; no config changes needed
- **Not yet production-ready**: language server and project references are still being ported
- Benchmark with `tsgo --diagnostics` to compare against `tsc`

```bash
# Install TS 7.0 Beta for benchmarking
npm install -D typescript@beta

# Run the Go compiler (beta CLI)
npx tsgo --diagnostics

# Compare with standard tsc
npx tsc --extendedDiagnostics
```

## Strict Mode Configuration (TS 6.0+)

```json
{
  "compilerOptions": {
    // Strict type checking (strict: true is default in TS 6.0+, shown explicitly for clarity)
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,

    // Additional checks
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,

    // Module resolution
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "resolveJsonModule": true,

    // Emit
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "removeComments": false,
    "importHelpers": true,
    "isolatedDeclarations": true,

    // Interop
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "forceConsistentCasingInFileNames": true,

    // Target (es2025 is default in TS 6.0+)
    "target": "es2025",
    "lib": ["es2025", "DOM", "DOM.Iterable"],

    // Skip checking
    "skipLibCheck": true
  }
}
```

## Project References

```json
// Root tsconfig.json
{
  "files": [],
  "references": [
    { "path": "./packages/shared" },
    { "path": "./packages/frontend" },
    { "path": "./packages/backend" }
  ]
}

// packages/shared/tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "declarationMap": true
  },
  "include": ["src/**/*"]
}

// packages/frontend/tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "references": [
    { "path": "../shared" }
  ],
  "include": ["src/**/*"]
}
```

## Module Resolution Strategies

```json
// NodeNext (default in TS 6.0+, recommended for Node.js)
{
  "compilerOptions": {
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "esModuleInterop": true
  }
}

// Bundler (for bundlers like Vite, esbuild, webpack)
{
  "compilerOptions": {
    "module": "esnext",
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "moduleDetection": "force"
  }
}

// Classic (legacy, avoid)
{
  "compilerOptions": {
    "module": "commonjs",
    "moduleResolution": "node"
  }
}
```

## Subpath Imports (TS 6.0+ preferred over paths)

TS 6.0 fully supports `package.json` `"imports"` field with proper declaration emit. Prefer `#/` subpath imports over `paths` aliases in new projects — they work with all tools (bundlers, Node.js, tsc) without extra config.

```json
// package.json
{
  "imports": {
    "#components/*": "./src/components/*",
    "#utils/*": "./src/utils/*",
    "#shared/*": "./packages/shared/src/*",
    "#types": "./src/types/index.ts"
  }
}
```

```typescript
// Usage with subpath imports (no tsconfig paths needed)
import { Button } from '#components/Button';
import { formatDate } from '#utils/date';
import type { User } from '#types';
```

## Path Mapping (legacy approach, still supported)

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@utils/*": ["src/utils/*"],
      "@shared/*": ["../shared/src/*"],
      "@types": ["src/types/index.ts"]
    }
  }
}
```

```typescript
// Usage with path mapping
import { Button } from '@components/Button';
import { formatDate } from '@utils/date';
import type { User } from '@types';
```

## Incremental Compilation

```json
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo",
    "composite": true
  }
}
```

## Declaration Files

```json
{
  "compilerOptions": {
    // Generate .d.ts files
    "declaration": true,
    "declarationMap": true,
    "emitDeclarationOnly": false,

    // Bundle declarations
    "declarationDir": "./types",

    // For libraries
    "stripInternal": true
  }
}
```

```typescript
// Using JSDoc for .d.ts generation
/**
 * Creates a user
 * @param name - User's name
 * @param email - User's email
 * @returns The created user
 * @example
 * ```ts
 * const user = createUser('John', 'john@example.com');
 * ```
 */
export function createUser(name: string, email: string): User {
  return { id: generateId(), name, email };
}
```

## Build Optimization

```json
{
  "compilerOptions": {
    // Performance
    "skipLibCheck": true,
    "skipDefaultLibCheck": true,

    // Faster builds
    "incremental": true,
    "isolatedDeclarations": true,
    "assumeChangesOnlyAffectDirectDependencies": true,

    // Smaller output
    "removeComments": true,
    "importHelpers": true,

    // Tree shaking support
    "module": "esnext",
    "target": "es2025"
  }
}
```

### TS 7.0 Beta Build Benchmark

```bash
# Compare tsc vs tsgo on your project
time npx tsc --extendedDiagnostics --noEmit
time npx tsgo --diagnostics --noEmit
```

## Multiple Configurations

```json
// tsconfig.json (base)
{
  "compilerOptions": {
    "strict": true,
    "target": "es2025"
  }
}

// tsconfig.build.json (production)
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "sourceMap": false,
    "removeComments": true,
    "declaration": true
  },
  "exclude": ["**/*.test.ts", "**/*.spec.ts"]
}

// tsconfig.test.json (testing)
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "types": ["jest", "node"],
    "esModuleInterop": true
  },
  "include": ["src/**/*.test.ts", "src/**/*.spec.ts"]
}
```

## Framework-Specific Configs

```json
// React + Vite (TS 6.0+)
{
  "compilerOptions": {
    "target": "es2025",
    "module": "esnext",
    "lib": ["es2025", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "isolatedDeclarations": true,
    "noEmit": true,
    "strict": true
  }
}

// Next.js (TS 6.0+)
{
  "compilerOptions": {
    "target": "es2025",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}

// Node.js + Express (TS 6.0+)
{
  "compilerOptions": {
    "target": "es2025",
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "lib": ["es2025"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "isolatedDeclarations": true,
    "sourceMap": true
  }
}
```

## Custom Type Definitions

```typescript
// src/types/global.d.ts
declare global {
  interface Window {
    myApp: {
      version: string;
      config: AppConfig;
    };
  }

  namespace NodeJS {
    interface ProcessEnv {
      DATABASE_URL: string;
      API_KEY: string;
      NODE_ENV: 'development' | 'production' | 'test';
    }
  }
}

export {};

// src/types/modules.d.ts
declare module '*.svg' {
  const content: string;
  export default content;
}

declare module '*.css' {
  const classes: { [key: string]: string };
  export default classes;
}

declare module 'untyped-library' {
  export function doSomething(value: string): number;
}
```

## Compiler API Usage

```typescript
// programmatic compilation
import ts from 'typescript';

function compile(fileNames: string[], options: ts.CompilerOptions): void {
  const program = ts.createProgram(fileNames, options);
  const emitResult = program.emit();

  const allDiagnostics = ts
    .getPreEmitDiagnostics(program)
    .concat(emitResult.diagnostics);

  allDiagnostics.forEach(diagnostic => {
    if (diagnostic.file) {
      const { line, character } = ts.getLineAndCharacterOfPosition(
        diagnostic.file,
        diagnostic.start!
      );
      const message = ts.flattenDiagnosticMessageText(
        diagnostic.messageText,
        '\n'
      );
      console.log(
        `${diagnostic.file.fileName} (${line + 1},${character + 1}): ${message}`
      );
    } else {
      console.log(
        ts.flattenDiagnosticMessageText(diagnostic.messageText, '\n')
      );
    }
  });

  const exitCode = emitResult.emitSkipped ? 1 : 0;
  console.log(`Process exiting with code '${exitCode}'.`);
  process.exit(exitCode);
}

compile(['src/index.ts'], {
  noEmitOnError: true,
  target: ts.ScriptTarget.ES2025,
  module: ts.ModuleKind.NodeNext,
  strict: true
});
```

## Performance Monitoring

```json
{
  "compilerOptions": {
    "diagnostics": true,
    "extendedDiagnostics": true,
    "generateCpuProfile": "profile.cpuprofile",
    "explainFiles": true
  }
}
```

```bash
# Run with diagnostics
tsc --diagnostics

# Extended diagnostics
tsc --extendedDiagnostics

# Generate trace
tsc --generateTrace trace

# Analyze with @typescript/analyze-trace
npx @typescript/analyze-trace trace
```

## Quick Reference

| Option | Purpose |
|--------|---------|
| `strict` | Enable all strict checks |
| `composite` | Enable project references |
| `incremental` | Enable incremental compilation |
| `skipLibCheck` | Skip .d.ts checking for faster builds |
| `esModuleInterop` | Better CommonJS interop |
| `moduleResolution` | How modules are resolved |
| `paths` | Path mapping for imports |
| `declaration` | Generate .d.ts files |
| `sourceMap` | Generate source maps |
| `noEmit` | Don't emit output (type check only) |
| `isolatedModules` | Each file can be transpiled separately |
| `isolatedDeclarations` | Generate .d.ts without cross-module inference (TS 6.0+ stable) |
| `allowImportingTsExtensions` | Import .ts files directly |
