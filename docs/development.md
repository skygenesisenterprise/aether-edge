# Development Guide

This guide covers how to set up a development environment, understand the codebase architecture, and contribute to Aether Edge.

## Development Environment Setup

### Prerequisites

- **Node.js**: 18.0+ with npm
- **Git**: For version control
- **Docker**: Optional but recommended for testing
- **VS Code**: Recommended IDE with extensions
- **WireGuard®**: For tunnel testing (optional)

### Local Development Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/fosrl/pangolin.git
cd pangolin
```

#### 2. Install Dependencies

```bash
npm install
```

#### 3. Environment Configuration

```bash
# Copy configuration template
cp config/config.example.yml config/config.yml

# Create environment file for development
cat > .env.development << EOF
NODE_ENV=development
ENVIRONMENT=dev
SERVER_SECRET=dev-secret-key-change-in-production
EOF
```

#### 4. Database Setup

**For SQLite (Recommended for Development):**
```bash
npm run set:sqlite
npm run db:sqlite:push
```

**For PostgreSQL:**
```bash
npm run set:pg
npm run db:pg:push
```

#### 5. Build Configuration

```bash
# Set build variant (oss for development)
npm run set:oss
```

#### 6. Start Development Server

```bash
npm run dev
```

The development server will start on:
- **Frontend**: http://localhost:3002
- **API Server**: http://localhost:3000
- **Internal API**: http://localhost:3001

### VS Code Setup

Install these recommended extensions:

```json
{
  "recommendations": [
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-eslint",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml"
  ]
}
```

Create `.vscode/settings.json`:

```json
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "files.associations": {
    "*.css": "tailwindcss"
  }
}
```

## Project Architecture

### Directory Structure

```
├── src/                          # Frontend (Next.js)
│   ├── app/                      # App Router pages
│   ├── components/               # React components
│   ├── contexts/                 # React contexts
│   ├── hooks/                    # Custom React hooks
│   ├── lib/                      # Frontend utilities
│   ├── providers/                # React providers
│   ├── services/                 # API service functions
│   └── types/                    # TypeScript type definitions
├── server/                       # Backend (Express.js)
│   ├── auth/                     # Authentication logic
│   ├── db/                       # Database models and migrations
│   ├── lib/                      # Backend utilities
│   ├── middlewares/              # Express middleware
│   ├── private/                  # Private API routes
│   ├── routers/                  # Public API routes
│   ├── setup/                    # Database setup scripts
│   └── types/                    # Backend TypeScript types
├── config/                       # Configuration files
├── docs/                         # Documentation
├── install/                      # Installation scripts
├── public/                       # Static assets
├── messages/                     # Internationalization files
└── test/                         # Test files
```

### Technology Stack

#### Frontend
- **Next.js 15**: React framework with App Router
- **React 19**: UI library
- **TypeScript**: Type-safe JavaScript
- **Tailwind CSS**: Utility-first CSS framework
- **Radix UI**: Component library
- **React Hook Form**: Form handling
- **Zustand**: State management
- **React Query**: Server state management

#### Backend
- **Express.js**: Web framework
- **TypeScript**: Type-safe JavaScript
- **Drizzle ORM**: Database ORM
- **WireGuard®**: VPN tunneling
- **Traefik**: Reverse proxy
- **Winston**: Logging
- **Node.js**: Runtime environment

#### Database
- **SQLite**: Default database (development)
- **PostgreSQL**: Production database option

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Follow the coding standards and patterns described below.

### 3. Test Your Changes

```bash
# Run linting
npm run lint

# Run type checking
npm run typecheck

# Run tests (when available)
npm test
```

### 4. Commit Changes

```bash
git add .
git commit -m "feat: add new feature description"
```

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Create a Pull Request following the template in `.github/PULL_REQUEST_TEMPLATE.md`.

## Coding Standards

### TypeScript

#### Type Definitions

Always use TypeScript interfaces and types:

```typescript
// Good
interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
}

// Bad
const user = {
  id: '',
  email: '',
  name: '',
  role: ''
};
```

#### Import Organization

```typescript
// External libraries first
import express from 'express';
import { z } from 'zod';

// Internal modules next
import { User } from '@server/db';
import config from '@server/lib/config';

// Relative imports last
import { validateUser } from './utils';
```

### React Components

#### Component Structure

```typescript
import React from 'react';
import { Button } from '@/components/ui/button';
import { useUser } from '@/hooks/useUser';

interface UserProfileProps {
  userId: string;
  onUpdate?: (user: User) => void;
}

export const UserProfile: React.FC<UserProfileProps> = ({
  userId,
  onUpdate
}) => {
  const { user, loading, error } = useUser(userId);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div className="user-profile">
      <h2>{user.name}</h2>
      <p>{user.email}</p>
      <Button onClick={() => onUpdate?.(user)}>
        Update Profile
      </Button>
    </div>
  );
};
```

#### Custom Hooks

```typescript
import { useState, useEffect } from 'react';
import { User } from '@/types';

export const useUser = (userId: string) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchUser = async () => {
      try {
        setLoading(true);
        const response = await fetch(`/api/users/${userId}`);
        const userData = await response.json();
        setUser(userData);
      } catch (err) {
        setError(err as Error);
      } finally {
        setLoading(false);
      }
    };

    fetchUser();
  }, [userId]);

  return { user, loading, error };
};
```

### Backend Code

#### Route Handlers

```typescript
import { z } from 'zod';
import { createRoute } from '@server/lib/route';
import { User } from '@server/db';

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  role: z.enum(['user', 'admin'])
});

export const createUserRoute = createRoute({
  method: 'POST',
  path: '/users',
  schema: createUserSchema,
  handler: async (input, context) => {
    const { email, name, role } = input;
    
    const user = await User.create({
      email,
      name,
      role
    });

    return { user };
  }
});
```

#### Middleware

```typescript
import { Request, Response, NextFunction } from 'express';
import { verifySession } from '@server/lib/auth';

export const authMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const session = await verifySession(req.headers.authorization);
    req.user = session.user;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized' });
  }
};
```

## Database Development

### Migrations

#### Creating Migrations

```bash
# SQLite
npm run db:sqlite:generate

# PostgreSQL
npm run db:pg:generate
```

#### Running Migrations

```bash
# SQLite
npm run db:sqlite:push

# PostgreSQL
npm run db:pg:push
```

### Schema Definition

```typescript
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: text('id').primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  role: text('role').notNull().default('user'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull()
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
```

## Testing

### Unit Tests

```typescript
import { describe, it, expect } from 'vitest';
import { validateEmail } from '@/utils/validation';

describe('validateEmail', () => {
  it('should validate correct email addresses', () => {
    expect(validateEmail('user@example.com')).toBe(true);
    expect(validateEmail('test.name+tag@domain.co.uk')).toBe(true);
  });

  it('should reject invalid email addresses', () => {
    expect(validateEmail('invalid-email')).toBe(false);
    expect(validateEmail('user@')).toBe(false);
  });
});
```

### Integration Tests

```typescript
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { createTestServer } from '@/test/server';
import { User } from '@server/db';

describe('User API', () => {
  let server: TestServer;

  beforeAll(async () => {
    server = await createTestServer();
  });

  afterAll(async () => {
    await server.close();
  });

  it('should create a new user', async () => {
    const response = await server.request
      .post('/api/v1/users')
      .send({
        email: 'test@example.com',
        name: 'Test User'
      });

    expect(response.status).toBe(201);
    expect(response.body.user.email).toBe('test@example.com');
  });
});
```

## Debugging

### Frontend Debugging

Use React DevTools and Redux DevTools for state inspection.

### Backend Debugging

```bash
# Start with Node.js debugging
node --inspect-brk dist/server.mjs

# Or use VS Code launch configuration
```

VS Code `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Server",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/dist/server.mjs",
      "env": {
        "NODE_ENV": "development"
      },
      "console": "integratedTerminal",
      "restart": true,
      "runtimeExecutable": "node"
    }
  ]
}
```

## Performance Optimization

### Frontend

- Use React.memo for component memoization
- Implement code splitting with dynamic imports
- Optimize images and assets
- Use React Query for efficient data fetching

### Backend

- Implement database indexes
- Use connection pooling
- Cache frequently accessed data
- Optimize database queries

## Security Considerations

### Input Validation

Always validate user input:

```typescript
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  password: z.string().min(8).regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
});
```

### Authentication

- Use secure session management
- Implement proper CSRF protection
- Validate API permissions
- Use HTTPS in production

### Data Protection

- Hash passwords with Argon2
- Encrypt sensitive data
- Implement proper access controls
- Log security events

## Internationalization

### Adding New Translations

1. Add translation keys to `messages/en-US.json`:

```json
{
  "user": {
    "profile": "User Profile",
    "settings": "User Settings"
  }
}
```

2. Add translations to other language files:

```json
// messages/fr-FR.json
{
  "user": {
    "profile": "Profil Utilisateur",
    "settings": "Paramètres Utilisateur"
  }
}
```

3. Use translations in components:

```typescript
import { useTranslations } from 'next-intl';

export const UserProfile = () => {
  const t = useTranslations('user');
  
  return (
    <div>
      <h1>{t('profile')}</h1>
      <h2>{t('settings')}</h2>
    </div>
  );
};
```

## Build and Deployment

### Development Build

```bash
# Build for development
npm run build:sqlite

# Start development server
npm start
```

### Production Build

```bash
# Set production environment
export NODE_ENV=production
export ENVIRONMENT=prod

# Build application
npm run build:sqlite

# Start production server
npm start
```

### Docker Development

```bash
# Build development image
docker build -f Dockerfile.dev -t pangolin:dev .

# Run development container
docker run -p 3000:3000 -p 3002:3002 pangolin:dev
```

## Contributing Guidelines

### Before Contributing

1. Read the [Code of Conduct](CODE_OF_CONDUCT.md)
2. Check existing issues and pull requests
3. Discuss significant changes in an issue first

### Making Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes following the coding standards
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

### Pull Request Process

1. Fill out the PR template completely
2. Link to related issues
3. Ensure CI passes
4. Request code review
5. Address feedback promptly

### Code Review Guidelines

- Focus on logic, security, and performance
- Suggest improvements constructively
- Check for adherence to coding standards
- Verify tests are adequate

## Getting Help

### Resources

- 📖 [Official Documentation](https://docs.pangolin.net)
- 💬 [GitHub Discussions](https://github.com/fosrl/pangolin/discussions)
- 🐛 [Issue Tracker](https://github.com/fosrl/pangolin/issues)
- 📧 [Developer Support](mailto:dev-support@pangolin.net)

### Community

- Join our [Discord Server](https://discord.gg/pangolin)
- Follow us on [Twitter](https://twitter.com/pangolin)
- Subscribe to our [Newsletter](https://pangolin.net/newsletter)

Thank you for contributing to Aether Edge! 🚀