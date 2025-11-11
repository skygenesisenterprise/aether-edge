// Re-export all router modules
export * from './apiKeys';
export * from './auditLogs';
export * from './blueprints';
export * from './certificates';
export * from './domain';
export * from './generatedLicense';
export * from './gerbil';
export * from './license';
// Use namespaces to avoid conflicts
export * as NewtRouter from './newt';
export * as OlmRouter from './olm';
export * from './role';
export * from './site';
export * from './user';
export * from './ws';