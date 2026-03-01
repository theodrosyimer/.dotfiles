# Code Samples Reference

## Three Ways to Add Code Samples

### 1. `x-codeSamples` in the OpenAPI Spec (Per-Endpoint)

Add directly to each operation in your spec. Best for endpoint-specific examples.

```json
{
  "paths": {
    "/auth/login": {
      "post": {
        "x-codeSamples": [
          {
            "lang": "typescript",
            "label": "Fetch",
            "source": "const res = await fetch('/auth/login', {\n  method: 'POST',\n  headers: { 'Content-Type': 'application/json' },\n  body: JSON.stringify({ email, password }),\n});"
          },
          {
            "lang": "bash",
            "label": "cURL",
            "source": "curl -X POST http://localhost:3001/auth/login \\\n  -H 'Content-Type: application/json' \\\n  -d '{\"email\": \"user@example.com\", \"password\": \"secret\"}'"
          }
        ]
      }
    }
  }
}
```

YAML equivalent:

```yaml
paths:
  /auth/login:
    post:
      x-codeSamples:
        - lang: typescript
          label: Fetch
          source: |
            const res = await fetch('/auth/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ email, password }),
            });
        - lang: bash
          label: cURL
          source: |
            curl -X POST http://localhost:3001/auth/login \
              -H 'Content-Type: application/json' \
              -d '{"email": "user@example.com", "password": "secret"}'
```

### 2. `generateCodeSamples` in `api-page.tsx` (Global)

Applied to ALL endpoints. Merged with `x-codeSamples` from the spec.

```typescript
// src/components/api-page.tsx
import { openapi } from '@/lib/openapi';
import { createAPIPage } from 'fumadocs-openapi/ui';

export const APIPage = createAPIPage(openapi, {
  generateCodeSamples(endpoint) {
    // `endpoint` is MethodInformation: { method, operationId, summary, ... }
    return [
      {
        id: 'fetch',
        lang: 'typescript',
        label: 'Fetch',
        source: `const response = await fetch('http://localhost:3001/<endpoint>', {
  method: '${endpoint.method.toUpperCase()}',
  headers: { Authorization: 'Bearer <token>' },
});`,
      },
    ];
  },
});
```

### 3. Disable a Default Sample

Set `source: false` on a sample ID to suppress it:

```typescript
generateCodeSamples(endpoint) {
  return [
    { id: 'curl', lang: 'bash', source: false }, // disable cURL
    { id: 'python', lang: 'python', label: 'Python', source: '...' },
  ];
}
```

## MethodInformation Properties

The `endpoint` parameter in `generateCodeSamples` exposes the dereferenced OpenAPI operation:

| Property | Type | Description |
|----------|------|-------------|
| `method` | `string` | HTTP method (`get`, `post`, `patch`, `delete`) |
| `operationId` | `string` | NestJS operation ID (e.g. `AuthController_login`) |
| `summary` | `string` | Endpoint summary |
| `description` | `string` | Endpoint description |
| `tags` | `string[]` | Operation tags |
| `parameters` | `ParameterObject[]` | Path/query/header params |
| `requestBody` | `RequestBodyObject` | Request body schema |
| `responses` | `Record<string, ResponseObject>` | Response schemas |
| `security` | `SecurityRequirement[]` | Security requirements |
| `x-codeSamples` | `CodeSample[]` | Spec-defined code samples |

## NestJS: Adding x-codeSamples via Decorators

```typescript
import { ApiExtension } from '@nestjs/swagger';

@Post('register')
@ApiExtension('x-codeSamples', [
  {
    lang: 'typescript',
    label: 'Fetch',
    source: `const res = await fetch('/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password, name }),
});`,
  },
  {
    lang: 'bash',
    label: 'cURL',
    source: `curl -X POST http://localhost:3001/auth/register \\
  -H 'Content-Type: application/json' \\
  -d '{"email": "user@example.com", "password": "pass", "name": "John"}'`,
  },
])
async register(@Body() dto: RegisterDto) { ... }
```

## Code Sample Language Identifiers

| Language | `lang` value | Common `label` |
|----------|-------------|----------------|
| TypeScript/JavaScript | `typescript` or `js` | Fetch / JS SDK |
| cURL | `bash` | cURL |
| Python | `python` | Python |
| Go | `go` | Go |
| Ruby | `ruby` | Ruby |
| PHP | `php` | PHP |
| Java | `java` | Java |
| C# | `csharp` | C# |
