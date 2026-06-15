---
name: product-analyze-service
description: Analyze existing service repository and generate complete documentation - architecture, API specs, DB schemas
argument-hint: "[service-repo-path]"
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion"
---

# Analyze Service

## Purpose

Analyze an existing service repository in depth and generate complete documentation including architecture, API specifications, and database schemas.

**Flow:**
```
Step 0: Validate Input & Detect Service
  |
Step 1: Deep Analysis of Service
  |
Step 2: Show Analysis Summary (user approval)
  |
Step 3: Generate Temporary Analysis Document
  |
Step 4: Generate Architecture Documentation
  |
Step 5: Generate API Specification (backend only)
  |
Step 6: Generate Database Schema (backend with DB only)
  |
Step 7: Update Import State
  |
Step 8: Summary
```

**Result:** Complete documentation for one service, ready for consolidation with `/product-consolidate-services`.

**This command does NOT:**
- Generate PRD (goals, requirements, feature groups)
- Consolidate multiple services into a single architecture
- Create the product repository structure

These are handled in `/product-consolidate-services`.

## Role

**Adopt the Technical Leader Agent role** - Read [Technical Leader Agent](.claude/agents/technical-leader.md)

## CRITICAL RULES

1. **Path required** - Service repository path must be provided as argument
2. **Use Spanish** for all user interactions and generated documents
   - Translate ALL content including section titles from English templates
   - Examples: "Goals" -> "Objetivos", "Background" -> "Contexto", "Success Criteria" -> "Criterios de Exito"
3. **Save first, then validate** - Save documents, notify user, wait for confirmation
4. **Reference locations from Files index** - Do not hardcode paths
5. **Extract from code** - Don't invent, extract actual patterns and decisions from codebase
6. **Do NOT dump full content in chat** - Save to file, show summary, let user review file directly

## Execution

### Step 0: Validate Input and Detect Service Type

**0.1 Validate Path**

Parse `$ARGUMENTS` as the service repository path.

If `$ARGUMENTS` is empty or no path was provided:

```markdown
Este comando requiere el path al repositorio del servicio.

**Uso:** `/product-analyze-service {path}`

**Ejemplos:**
- `/product-analyze-service ../api-backend`
- `/product-analyze-service /home/user/projects/web-app`
- `/product-analyze-service ../services/notification-service`

**Tip:** Usa paths relativos desde el repositorio de producto.
```

**ABORT if no path provided.**

**0.2 Validate Path Exists**

Check if directory exists:
- If not found: Error with clear message, abort
- If found but not a repository: Warn and ask for confirmation

**0.3 Load Context**

1. Read [Files index](.claude/utils/index.md) to get all locations
2. Identify key folders for output

**0.4 Quick Detection**

Read repository to detect basic information:

1. **Service name:**
   - From package.json "name" field
   - Or from folder name as fallback

2. **Service type:**
   - **Backend** if: NestJS, Express, Fastify, Python Flask/Django, Go, etc.
   - **Frontend** if: React, Vue, Angular, Next.js, Nuxt, etc.
   - Check package.json dependencies and project structure

3. **Tech stack (preliminary):**
   - Framework (React, NestJS, etc.)
   - Language (TypeScript, JavaScript, Python, etc.)
   - Database if backend (PostgreSQL, MongoDB, etc.)

**0.5 Confirm with User**

```markdown
Servicio detectado: **{service-name}**

- **Tipo:** {Backend / Frontend}
- **Path:** {relative-path}
- **Framework:** {framework}
- **Lenguaje:** {language}

Es correcto? Queres continuar con el analisis?

(Escribi "si", "ok", o "continuar" para proceder)
```

**WAIT for user confirmation.**

---

### Step 1: Deep Analysis of Service

**Explore the service repository thoroughly.**

#### If Backend:

1. **Tech Stack (detailed):**
   - Framework and version
   - Language and version
   - Database type and ORM
   - Testing framework
   - Other key libraries (validation, auth, etc.)

2. **Project Structure:**
   - Main folders and their purposes
   - Module/layer organization
   - How code is structured (MVC, Clean Architecture, etc.)

3. **API Endpoints:**
   - List all routes/endpoints
   - HTTP methods
   - Controllers and their responsibilities
   - Group by domain/module

4. **Database:**
   - Extract models/entities from ORM
   - Field types and constraints
   - Relationships between entities
   - Identify primary database name

5. **Authentication & Authorization:**
   - Strategy (JWT, OAuth, sessions)
   - How it's implemented
   - Protected routes patterns

6. **Middlewares & Patterns:**
   - Custom middlewares
   - Error handling patterns
   - Validation approach
   - Logging/monitoring

7. **External Dependencies:**
   - Third-party APIs consumed
   - External services (email, storage, etc.)
   - SDKs used

8. **Testing:**
   - Unit tests structure
   - Integration tests
   - E2E tests if any

9. **Configuration:**
   - Environment variables patterns
   - Configuration structure

#### If Frontend:

1. **Tech Stack (detailed):**
   - Framework and version
   - Language and version
   - State management library
   - Styling approach
   - Build tool
   - Testing framework

2. **Project Structure:**
   - Components organization
   - Pages/routes structure
   - Hooks/composables
   - Services/utils

3. **Routing:**
   - All routes defined
   - Route structure
   - Navigation patterns

4. **State Management:**
   - How state is organized
   - Stores/context structure
   - Global vs local state patterns

5. **API Integration:**
   - How backend is consumed
   - API client setup
   - Endpoints called
   - Error handling

6. **Component Patterns:**
   - UI components (buttons, inputs, modals, etc.)
   - Layout components
   - Reusable patterns
   - Props patterns

7. **Styling:**
   - Approach (Tailwind, CSS Modules, Styled Components, etc.)
   - Theme/design tokens if any
   - Color palette, spacing scale

8. **Testing:**
   - Component test patterns
   - Integration test approach

9. **Configuration:**
   - Environment variables
   - Build configuration

#### Both (Backend & Frontend):

10. **Features Detected:**
    - Group by domain/module
    - What functionality each provides
    - User-facing features

11. **Interfaces:**
    - **Exposes:** What this service provides (API, UI, events)
    - **Consumes:** What it depends on (APIs, DBs, services)

12. **Detected Flows (Partial):**
    - Identify cross-service interactions by detecting:
      - HTTP client calls to other services (fetch, axios, HttpService, etc.)
      - Event publishers (emit, publish, dispatch patterns)
      - Event consumers/subscribers (on, subscribe, listen patterns)
      - Webhook endpoints or callers
    - For each detected interaction, note:
      - Source service (this one)
      - Target service or event name
      - Endpoint or event being called/published
      - Data shape if identifiable from code

13. **Technical Decisions:**
    - Why this framework was chosen (infer from codebase)
    - Why this database/state management
    - Architecture patterns chosen
    - Key technical choices

---

### Step 2: Show Analysis Summary

Present comprehensive analysis to user:

```markdown
## Analisis Completo: {service-name}

### Stack Tecnico Detectado
{Detailed tech stack with versions}

### Estructura del Proyecto
{Description of folder organization and architecture pattern}

### Features Principales

#### {Domain 1}
- {Feature 1}
- {Feature 2}

#### {Domain 2}
- {Feature 1}
- {Feature 2}

{Continue for all domains}

### Interfaces

**Expone:**
- {What it provides - API with N endpoints, Web UI, Events published, etc.}

**Consume:**
- {What it depends on - databases, external APIs, other services}

### Decisiones Tecnicas Identificadas

1. **{Framework}**: {Why chosen - inferred from patterns}
2. **{Database/State}**: {Why chosen}
3. **{Other key decisions}**

### Estadisticas
- **Endpoints/Rutas:** {N}
- **Modelos/Entidades:** {N} {if backend}
- **Componentes:** {N} {if frontend}
- **Tests:** {N tests found}

---

**Voy a generar la documentacion completa basandome en este analisis:**

**Arquitectura Detallada**
   - docs/architectures/{service-name}/ ({10+} secciones)

{If backend:}
**API Specification**
   - docs/apis/{service-name}.yaml (OpenAPI con {N} endpoints)

{If backend with database:}
**Database Schema**
   - docs/db-schemas/{db-name}.md ({N} entidades)

**Analisis Temporal**
   - docs/analysis/services/{service-name}.md (para consolidacion)

**Continuar con la generacion de documentacion?**
```

**WAIT for user approval.**

---

### Step 3: Generate Temporary Analysis Document

**3.1 Create document**

Create `docs/analysis/services/{service-name}.md` with:
- Identification (name, type, purpose, tech stack, responsibility)
- Main features (grouped by domain)
- Technical decisions (with "why" inferred)
- Interfaces (exposes/consumes)
- Information for PRD consolidation
- Detected flows (partial cross-service interactions found in code)
- References to generated documentation

**3.2 Notify user** (do NOT show full content)

```markdown
Documento guardado: `docs/analysis/services/{service-name}.md`

Incluye:
- Identificacion del servicio (proposito, tech stack, responsabilidad)
- Features principales agrupadas por dominio
- Decisiones tecnicas identificadas
- Interfaces (expone/consume)

**Revisa el archivo y decime si esta correcto o queres cambios.**
```

**If user requests changes:**
- Edit the file with requested changes
- Notify user again
- Repeat until approved

---

### Step 4: Generate Architecture Documentation

**4.1 Read Template Specification**

Read the appropriate template from Files index:
- **Backend:** Read **Backend Architecture Document Template**
- **Frontend:** Read **Frontend Architecture Document Template**

Understand the EXACT structure, format, subsections, and examples defined in the template.

**4.2 Generate Architecture Files**

Generate all architecture files in `docs/architectures/{service-name}/`

**If Backend:**
1. **index.md** - Links to all sections
2. **tech-stack.md** - Detected stack with versions and justification
3. **project-structure.md** - Analyzed folder structure with explanations
4. **api-standards.md** - Patterns found in code (REST conventions, error handling, etc.)
5. **data-layer.md** - Database access patterns, ORM usage, repositories
6. **service-layer.md** - Business logic organization, service patterns
7. **authentication.md** - Auth strategy and implementation
8. **testing.md** - Test structure and patterns found
9. **environment.md** - Environment variables and configuration
10. **deployment.md** - Deployment configs if found (Dockerfile, etc.)
11. **developer-standards.md** - Code style, naming conventions observed

**If Frontend:**
1. **index.md** - Links to all sections
2. **tech-stack.md** - Detected stack with versions
3. **project-structure.md** - Folder structure with explanations
4. **component-standards.md** - Component patterns and examples from code
5. **state-management.md** - State patterns and store examples
6. **api-integration.md** - How API is consumed, client setup
7. **routing.md** - Routes structure and navigation
8. **styling.md** - Styling approach and theme tokens
9. **testing.md** - Test patterns found
10. **environment.md** - Environment variables and config
11. **developer-standards.md** - Code conventions observed

**CRITICAL RULES for each section:**

1. **Check if section has subsections** in template (look for `subsections` array)
2. **If section has subsections:**
   - Generate section title as `# {Section Title}`
   - For EACH subsection in template's `subsections` array:
     - Generate subsection heading as `## {Subsection Title}` (exact title from template)
     - Follow the subsection's `format` specification
     - Adapt code examples to detected stack
   - Even if project doesn't follow pattern exactly, show actual pattern under expected subsection structure
3. **If section has NO subsections:**
   - Follow section's `format` specification directly
4. **Tables:** If template shows TABLE -> generate markdown table with same columns
5. **NO invention:** Do NOT create your own subsections - only use what's defined in template

**4.3 Notify user** (do NOT show full content)

```markdown
Arquitectura guardada: `docs/architectures/{service-name}/` ({N} archivos)

Incluye:
{If backend:}
- Tech stack, project structure, API standards
- Data layer, service layer, authentication
- Testing, environment, deployment
- Developer standards
{If frontend:}
- Tech stack, project structure, component standards
- State management, API integration, routing
- Styling, testing, environment
- Developer standards

**Revisa los archivos y decime si estan correctos o queres cambios.**
```

**If user requests changes:**
- Edit specific architecture files with requested changes
- Notify user again
- Repeat until approved

---

### Step 5: Generate API Specification (Backend only)

**Skip this step if frontend.**

**5.1 Extract from code**

Create `docs/apis/{service-name}.yaml` with OpenAPI 3.0 spec:

- All paths with HTTP methods (from routes/controllers)
- Request parameters (query, path, body)
- Request body schemas (from DTOs/validators)
- Response schemas (from return types)
- Authentication schemes (from guards/middleware)
- Tags by domain/module
- Error responses

**5.2 Notify user** (do NOT show full content)

```markdown
API spec guardado: `docs/apis/{service-name}.yaml`

Incluye:
- {N} endpoints con metodos HTTP
- Request parameters y body schemas
- Response schemas
- Authentication schemes
- Tags por dominio/modulo

**Revisa el archivo y decime si esta correcto o queres cambios.**
```

**If user requests changes:**
- Edit the OpenAPI file with requested changes
- Notify user again
- Repeat until approved

---

### Step 6: Generate Database Schema (Backend with DB only)

**Skip this step if frontend or no database.**

**6.1 Extract from ORM**

Create `docs/db-schemas/{database-name}.md` with:

- Database overview (type, purpose)
- Entity definitions (all fields from ORM models)
- Mermaid ER diagram showing relationships
- DBML representation
- Migrations strategy (if migration files found)

Extract from: Prisma schema, TypeORM entities, Sequelize models, Mongoose schemas, etc.

**6.2 Notify user** (do NOT show full content)

```markdown
Database schema guardado: `docs/db-schemas/{database-name}.md`

Incluye:
- Database overview (tipo, proposito)
- {N} entidades con campos documentados
- Mermaid ER diagram
- DBML representation
- Migrations strategy

**Revisa el archivo y decime si esta correcto o queres cambios.**
```

**If user requests changes:**
- Edit the schema file with requested changes
- Notify user again
- Repeat until approved

---

### Step 7: Update Import State

Create or update `docs/.import-state.yaml`:

```yaml
import:
  status: analyzing
  last_updated: {timestamp}

  services:
    - name: {service-name}
      type: {backend/frontend}
      responsibility: "{one-line description from analysis}"
      tech_stack: "{main stack}"
      path: {relative-path}
      status: analyzed
      analyzed_at: {timestamp}

      interfaces:
        exposes:
          - type: {rest_api / web_ui / events}
            details: "{description}"
        consumes:
          - type: {api / database / external_service}
            target: "{name or URL pattern}"
            details: "{description}"
```

---

### Step 8: Summary

Present final summary:

```markdown
## Servicio Analizado: {service-name}

### Documentacion Generada

**Analisis Temporal:**
- docs/analysis/services/{service-name}.md

**Arquitectura Completa:**
- docs/architectures/{service-name}/ ({N} secciones)

{If backend:}
**API Specification:**
- docs/apis/{service-name}.yaml ({N} endpoints)

{If backend with DB:}
**Database Schema:**
- docs/db-schemas/{db-name}.md ({N} entidades)

**Estado de Importacion:**
- docs/.import-state.yaml (actualizado)

---

### Siguientes Pasos

**Opcion 1: Analizar mas servicios**
Si tenes mas servicios, ejecuta:
```
/product-analyze-service {path-to-next-service}
```

**Opcion 2: Consolidar cuando estes listo**
Cuando hayas analizado todos los servicios, ejecuta:
```
/product-consolidate-services
```
Esto generara el PRD completo consolidando toda la informacion.

---

**Servicios analizados hasta ahora:** {N} (segun import-state.yaml)
```

## Output

Files saved to respective folders (see Files index for locations):

- `docs/analysis/services/{service-name}.md` - Temporary analysis for consolidation
- `docs/architectures/{service-name}/` - Complete architecture (10+ sections)
- `docs/apis/{service-name}.yaml` - OpenAPI spec (backend only)
- `docs/db-schemas/{database}.md` - DB schema (backend with DB only)
- `docs/.import-state.yaml` - Updated import state
