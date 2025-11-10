# API Documentation

Aether Edge provides a comprehensive RESTful API for managing all aspects of the platform. The API follows REST conventions and uses JSON for data exchange.

## Base URL

- **Production API**: `http://your-domain.com:3000/api/v1`
- **Development API**: `http://localhost:3000/api/v1`

## Authentication

### Session-Based Authentication

Most API endpoints require session-based authentication. Users must log in through the web interface or API to establish a session.

```http
GET /api/v1/user/profile
Cookie: session-id=your-session-token
```

### API Key Authentication

For programmatic access, use API keys in the `X-API-Key` header:

```http
GET /api/v1/sites
X-API-Key: your-api-key-here
```

### Creating API Keys

```http
POST /api/v1/api-keys/root/create
Content-Type: application/json
Authorization: Bearer your-session-token

{
  "name": "My API Key",
  "actions": ["site:read", "site:write"],
  "expiresAt": "2024-12-31T23:59:59Z"
}
```

## API Endpoints

### Authentication Endpoints

#### User Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### User Logout
```http
POST /api/v1/auth/logout
```

#### Get Current User
```http
GET /api/v1/user/profile
```

### Site Management

#### List Sites
```http
GET /api/v1/sites
```

**Response:**
```json
{
  "sites": [
    {
      "id": "site-uuid",
      "name": "Main Office",
      "description": "Primary office location",
      "subnet": "10.0.1.0/24",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### Create Site
```http
POST /api/v1/sites/create
Content-Type: application/json

{
  "name": "Branch Office",
  "description": "Secondary office location",
  "subnet": "10.0.2.0/24"
}
```

#### Get Site
```http
GET /api/v1/sites/{siteId}
```

#### Update Site
```http
PUT /api/v1/sites/{siteId}
Content-Type: application/json

{
  "name": "Updated Site Name",
  "description": "Updated description"
}
```

#### Delete Site
```http
DELETE /api/v1/sites/{siteId}
```

### Resource Management

#### List Resources
```http
GET /api/v1/resources
```

#### Create Proxy Resource
```http
POST /api/v1/resources/proxy/create
Content-Type: application/json

{
  "name": "Web Application",
  "protocol": "http",
  "fullDomain": "app.example.com",
  "hostHeader": "app.example.com",
  "targets": [
    {
      "siteId": "site-uuid",
      "hostname": "localhost",
      "port": 8080,
      "path": "/",
      "pathMatchType": "prefix"
    }
  ],
  "rules": [
    {
      "action": "allow",
      "match": "ip",
      "value": "192.168.1.0/24"
    }
  ]
}
```

#### Create Client Resource
```http
POST /api/v1/resources/client/create
Content-Type: application/json

{
  "name": "Database Access",
  "protocol": "tcp",
  "proxyPort": 5432,
  "hostname": "db.internal",
  "internalPort": 5432,
  "siteId": "site-uuid"
}
```

### User Management

#### List Users
```http
GET /api/v1/users
```

#### Create User
```http
POST /api/v1/users/create
Content-Type: application/json

{
  "email": "newuser@example.com",
  "name": "John Doe",
  "role": "user"
}
```

#### Invite User
```http
POST /api/v1/users/invite
Content-Type: application/json

{
  "email": "invite@example.com",
  "role": "member",
  "sites": ["site-uuid"]
}
```

#### Update User
```http
PUT /api/v1/users/{userId}
Content-Type: application/json

{
  "name": "Updated Name",
  "role": "admin"
}
```

### Organization Management

#### Get Organization
```http
GET /api/v1/org
```

#### Update Organization
```http
PUT /api/v1/org
Content-Type: application/json

{
  "name": "Updated Org Name",
  "settings": {
    "requireEmailVerification": true,
    "disableUserCreateOrg": false
  }
}
```

### Domain Management

#### List Domains
```http
GET /api/v1/domains
```

#### Create Domain
```http
POST /api/v1/domains/create
Content-Type: application/json

{
  "baseDomain": "example.com",
  "ssl": {
    "enabled": true,
    "email": "admin@example.com"
  }
}
```

#### Get DNS Records
```http
GET /api/v1/domains/{domainId}/dns
```

### API Key Management

#### List API Keys
```http
GET /api/v1/api-keys/root
```

#### Create API Key
```http
POST /api/v1/api-keys/root/create
Content-Type: application/json

{
  "name": "Service Key",
  "actions": ["site:read", "resource:read"],
  "expiresAt": "2024-12-31T23:59:59Z"
}
```

#### Delete API Key
```http
DELETE /api/v1/api-keys/{keyId}
```

### Blueprint Management

#### List Blueprints
```http
GET /api/v1/blueprints
```

#### Apply Blueprint
```http
POST /api/v1/blueprints/apply
Content-Type: application/json

{
  "name": "Infrastructure Setup",
  "resources": {
    "client-resources": {
      "web-app": {
        "name": "Web Application",
        "protocol": "tcp",
        "proxyPort": 80,
        "hostname": "web.internal",
        "internalPort": 8080,
        "site": "main-site"
      }
    },
    "proxy-resources": {
      "api-proxy": {
        "name": "API Gateway",
        "protocol": "http",
        "fullDomain": "api.example.com",
        "targets": [
          {
            "site": "main-site",
            "hostname": "api.internal",
            "port": 3000,
            "path": "/",
            "pathMatchType": "prefix"
          }
        ]
      }
    }
  }
}
```

### Audit Logs

#### Query Audit Logs
```http
POST /api/v1/audit-logs/query
Content-Type: application/json

{
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-01-31T23:59:59Z",
  "userId": "user-uuid",
  "action": "site:create",
  "limit": 100,
  "offset": 0
}
```

#### Export Audit Logs
```http
POST /api/v1/audit-logs/export
Content-Type: application/json

{
  "format": "csv",
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-01-31T23:59:59Z"
}
```

## WebSocket API

Aether Edge provides real-time updates through WebSocket connections.

### Connection

```javascript
const ws = new WebSocket('ws://localhost:3000/api/v1/ws');

// Authenticate after connection
ws.send(JSON.stringify({
  type: 'auth',
  token: 'your-session-token'
}));
```

### Message Types

#### Site Status Updates
```json
{
  "type": "site_status",
  "siteId": "site-uuid",
  "status": "online",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### Resource Updates
```json
{
  "type": "resource_update",
  "resourceId": "resource-uuid",
  "action": "created",
  "data": { /* resource data */ }
}
```

#### Connection Events
```json
{
  "type": "connection_event",
  "userId": "user-uuid",
  "action": "connected",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## Error Handling

### HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `422 Unprocessable Entity` - Validation error
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": {
      "field": "email",
      "value": "invalid-email"
    }
  }
}
```

## Rate Limiting

API requests are rate-limited to prevent abuse:

- **Default Limit**: 100 requests per minute per IP
- **Authenticated Users**: 1000 requests per minute
- **API Keys**: 5000 requests per minute

Rate limit headers are included in responses:

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Pagination

List endpoints support pagination using `limit` and `offset` parameters:

```http
GET /api/v1/sites?limit=20&offset=40
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "total": 100,
    "limit": 20,
    "offset": 40,
    "hasMore": true
  }
}
```

## Filtering and Sorting

### Filtering

Many endpoints support filtering via query parameters:

```http
GET /api/v1/users?role=admin&status=active
```

### Sorting

Use the `sort` parameter to specify sorting:

```http
GET /api/v1/sites?sort=name:asc,createdAt:desc
```

## OpenAPI Specification

The complete OpenAPI 3.0 specification is available at:

```
http://localhost:3000/api/docs
```

You can also access the JSON specification:

```
http://localhost:3000/api/docs.json
```

## SDK Examples

### JavaScript/Node.js

```javascript
import axios from 'axios';

const client = axios.create({
  baseURL: 'http://localhost:3000/api/v1',
  headers: {
    'X-API-Key': 'your-api-key'
  }
});

// List sites
const sites = await client.get('/sites');

// Create a site
const site = await client.post('/sites/create', {
  name: 'New Site',
  subnet: '10.0.3.0/24'
});
```

### Python

```python
import requests

client = requests.Session()
client.headers.update({'X-API-Key': 'your-api-key'})
client.base_url = 'http://localhost:3000/api/v1'

# List sites
response = client.get('/sites')
sites = response.json()

# Create a site
response = client.post('/sites/create', json={
    'name': 'New Site',
    'subnet': '10.0.3.0/24'
})
site = response.json()
```

### cURL

```bash
# List sites
curl -H "X-API-Key: your-api-key" \
     http://localhost:3000/api/v1/sites

# Create a site
curl -X POST \
     -H "Content-Type: application/json" \
     -H "X-API-Key: your-api-key" \
     -d '{"name":"New Site","subnet":"10.0.3.0/24"}' \
     http://localhost:3000/api/v1/sites/create
```

## Webhooks

Aether Edge can send webhook notifications for various events:

### Configure Webhooks

```http
POST /api/v1/webhooks/create
Content-Type: application/json

{
  "url": "https://your-service.com/webhook",
  "events": ["site.created", "user.updated"],
  "secret": "webhook-secret"
}
```

### Webhook Payload

```json
{
  "event": "site.created",
  "timestamp": "2024-01-01T00:00:00Z",
  "data": {
    "site": { /* site data */ }
  },
  "signature": "sha256=signature"
}
```

## API Versioning

The API is versioned using URL paths. The current version is `v1`. Backward compatibility is maintained within each major version.

### Version Headers

You can also specify the API version using headers:

```http
GET /api/sites
Accept: application/vnd.pangolin.v1+json
```

## Testing the API

### Using the Interactive Docs

Visit `http://localhost:3000/api/docs` for interactive API documentation with testing capabilities.

### Using Postman

Import the OpenAPI specification into Postman:

1. Go to `http://localhost:3000/api/docs.json`
2. Copy the JSON
3. In Postman: Import > Raw Text > Paste JSON
4. Set up authentication (API key or session)

## Support

For API-related questions:

- 📖 [API Reference](https://docs.pangolin.net/api)
- 💬 [GitHub Discussions](https://github.com/fosrl/pangolin/discussions)
- 🐛 [Report Issues](https://github.com/fosrl/pangolin/issues)
- 📧 [API Support](mailto:api-support@pangolin.net)