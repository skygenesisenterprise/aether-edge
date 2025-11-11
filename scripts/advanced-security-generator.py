#!/usr/bin/env python3
"""
Aether Edge Advanced Security Generator
Advanced cryptographic security generator with entropy analysis and validation
"""

import secrets
import string
import hashlib
import base64
import ssl
import subprocess
import sys
import argparse
import json
import os
from datetime import datetime
from typing import Dict, List, Tuple, Optional
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import hashes
from cryptography import x509
from cryptography.x509.oid import NameOID

class SecurityGenerator:
    """Advanced security generator with cryptographic functions"""
    
    def __init__(self):
        self.min_entropy = 3.0  # Minimum entropy threshold
        self.colors = {
            'red': '\033[0;31m',
            'green': '\033[0;32m',
            'yellow': '\033[1;33m',
            'blue': '\033[0;34m',
            'purple': '\033[0;35m',
            'cyan': '\033[0;36m',
            'nc': '\033[0m'
        }
    
    def log(self, message: str, color: str = 'nc'):
        """Print colored log message"""
        print(f"{self.colors[color]}{message}{self.colors['nc']}")
    
    def log_header(self, title: str):
        """Print header"""
        self.log(f"=== {title} ===", 'purple')
    
    def calculate_entropy(self, data: str) -> float:
        """Calculate Shannon entropy of data"""
        if not data:
            return 0.0
        
        # Count character frequencies
        char_counts = {}
        for char in data:
            char_counts[char] = char_counts.get(char, 0) + 1
        
        # Calculate entropy
        entropy = 0.0
        data_len = len(data)
        
        for count in char_counts.values():
            probability = count / data_len
            if probability > 0:
                entropy -= probability * (probability.bit_length() - 1)
        
        return entropy
    
    def validate_strength(self, secret: str, name: str = "secret") -> Dict:
        """Validate secret strength and return analysis"""
        analysis = {
            'name': name,
            'length': len(secret),
            'entropy': self.calculate_entropy(secret),
            'has_lowercase': any(c.islower() for c in secret),
            'has_uppercase': any(c.isupper() for c in secret),
            'has_digits': any(c.isdigit() for c in secret),
            'has_special': any(c in string.punctuation for c in secret),
            'common_patterns': [],
            'strength_score': 0,
            'recommendations': []
        }
        
        # Check for common patterns
        common_patterns = ['password', 'secret', 'key', 'admin', '123', 'test', 'qwerty']
        secret_lower = secret.lower()
        for pattern in common_patterns:
            if pattern in secret_lower:
                analysis['common_patterns'].append(pattern)
        
        # Calculate strength score (0-100)
        score = 0
        
        # Length scoring (0-30 points)
        if analysis['length'] >= 32:
            score += 30
        elif analysis['length'] >= 24:
            score += 25
        elif analysis['length'] >= 16:
            score += 20
        elif analysis['length'] >= 12:
            score += 15
        elif analysis['length'] >= 8:
            score += 10
        
        # Character variety scoring (0-30 points)
        variety_score = 0
        if analysis['has_lowercase']:
            variety_score += 7.5
        if analysis['has_uppercase']:
            variety_score += 7.5
        if analysis['has_digits']:
            variety_score += 7.5
        if analysis['has_special']:
            variety_score += 7.5
        score += variety_score
        
        # Entropy scoring (0-40 points)
        entropy_score = min(40, (analysis['entropy'] / 6.0) * 40)
        score += entropy_score
        
        # Deduct points for common patterns
        analysis['strength_score'] = max(0, score - (len(analysis['common_patterns']) * 10))
        
        # Generate recommendations
        if analysis['length'] < 16:
            analysis['recommendations'].append("Increase length to at least 16 characters")
        if not analysis['has_lowercase']:
            analysis['recommendations'].append("Add lowercase letters")
        if not analysis['has_uppercase']:
            analysis['recommendations'].append("Add uppercase letters")
        if not analysis['has_digits']:
            analysis['recommendations'].append("Add numbers")
        if not analysis['has_special']:
            analysis['recommendations'].append("Add special characters")
        if analysis['entropy'] < 3.5:
            analysis['recommendations'].append("Increase entropy (add more character variety)")
        
        return analysis
    
    def generate_secure_bytes(self, length: int) -> bytes:
        """Generate cryptographically secure random bytes"""
        return secrets.token_bytes(length)
    
    def generate_secure_hex(self, length: int) -> str:
        """Generate cryptographically secure hex string"""
        return secrets.token_hex(length // 2)
    
    def generate_secure_base64(self, length: int) -> str:
        """Generate cryptographically secure base64 string"""
        return secrets.token_urlsafe(length)[:length].replace('-', '').replace('_', '')
    
    def generate_secure_string(self, length: int, charset: str = None) -> str:
        """Generate cryptographically secure string from charset"""
        if charset is None:
            charset = string.ascii_letters + string.digits + string.punctuation
        return ''.join(secrets.choice(charset) for _ in range(length))
    
    def generate_password(self, min_length: int = 16, max_length: int = 32, 
                      require_upper: bool = True, require_lower: bool = True,
                      require_digits: bool = True, require_special: bool = True,
                      exclude_ambiguous: bool = True) -> str:
        """Generate cryptographically secure password with policy requirements"""
        
        # Define character sets
        if exclude_ambiguous:
            lowercase = 'abcdefghjkmnpqrstuvwxyz'  # Exclude i, l, o, q
            uppercase = 'ABCDEFGHJKLMNPQRSTUVWXYZ'  # Exclude I, L, O, Q
            digits = '23456789'  # Exclude 0, 1
            special = '!@#$%^&*()_+-='
        else:
            lowercase = string.ascii_lowercase
            uppercase = string.ascii_uppercase
            digits = string.digits
            special = string.punctuation
        
        # Build required characters
        password_chars = []
        if require_lower:
            password_chars.append(secrets.choice(lowercase))
        if require_upper:
            password_chars.append(secrets.choice(uppercase))
        if require_digits:
            password_chars.append(secrets.choice(digits))
        if require_special:
            password_chars.append(secrets.choice(special))
        
        # Fill remaining length
        all_chars = lowercase + uppercase + digits + special
        remaining_length = secrets.randbelow(max_length - min_length + 1) + min_length - len(password_chars)
        
        for _ in range(remaining_length):
            password_chars.append(secrets.choice(all_chars))
        
        # Shuffle the password
        secrets.SystemRandom().shuffle(password_chars)
        
        return ''.join(password_chars)
    
    def generate_jwt_secret(self, length: int = 64) -> str:
        """Generate JWT secret with high entropy"""
        self.log(f"Generating JWT secret ({length} bytes)...", 'blue')
        return self.generate_secure_base64(length)
    
    def generate_encryption_key(self, length: int = 32) -> Tuple[str, str]:
        """Generate encryption key and derived key"""
        self.log(f"Generating encryption key ({length} bytes)...", 'blue')
        
        # Generate main key
        main_key = self.generate_secure_bytes(length)
        main_key_b64 = base64.b64encode(main_key).decode()
        
        # Generate derived key for additional security
        salt = self.generate_secure_bytes(16)
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        derived_key = kdf.derive(main_key)
        derived_key_b64 = base64.b64encode(derived_key).decode()
        
        return main_key_b64, derived_key_b64
    
    def generate_api_key(self, length: int = 64, prefix: str = "aether") -> str:
        """Generate API key with prefix"""
        self.log(f"Generating API key ({length} characters)...", 'blue')
        key_part = self.generate_secure_string(length - len(prefix) - 1, 
                                         string.ascii_letters + string.digits)
        return f"{prefix}_{key_part}"
    
    def generate_webhook_secret(self, length: int = 32) -> str:
        """Generate webhook secret"""
        self.log(f"Generating webhook secret ({length} bytes)...", 'blue')
        return self.generate_secure_base64(length)
    
    def generate_database_credentials(self, db_type: str = "postgresql") -> Dict[str, str]:
        """Generate database credentials"""
        self.log(f"Generating {db_type} credentials...", 'blue')
        
        username = f"aether_user_{secrets.token_hex(8)}"
        password = self.generate_password(24, 32)
        
        credentials = {
            'username': username,
            'password': password,
            'connection_string': self.build_connection_string(db_type, username, password)
        }
        
        return credentials
    
    def build_connection_string(self, db_type: str, username: str, password: str,
                           host: str = "localhost", port: int = 5432, 
                           database: str = "aether_edge") -> str:
        """Build database connection string"""
        if db_type.lower() in ["postgresql", "pg"]:
            return f"postgresql://{username}:{password}@{host}:{port}/{database}"
        elif db_type.lower() == "mysql":
            return f"mysql://{username}:{password}@{host}:{port}/{database}"
        elif db_type.lower() == "sqlite":
            return f"sqlite:///app/data/{database}.db"
        else:
            raise ValueError(f"Unsupported database type: {db_type}")
    
    def generate_rsa_keys(self, key_size: int = 2048) -> Tuple[str, str]:
        """Generate RSA key pair"""
        self.log(f"Generating RSA {key_size}-bit key pair...", 'blue')
        
        # Generate private key
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=key_size
        )
        
        # Serialize private key
        private_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        
        # Generate public key
        public_key = private_key.public_key()
        public_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        return private_pem.decode(), public_pem.decode()
    
    def generate_ssl_certificate(self, domain: str = "localhost", 
                            key_size: int = 2048,
                            days_valid: int = 365) -> Tuple[str, str, str]:
        """Generate self-signed SSL certificate"""
        self.log(f"Generating SSL certificate for {domain}...", 'blue')
        
        # Generate private key
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=key_size
        )
        
        # Create certificate subject
        subject = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "California"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "San Francisco"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Aether Edge"),
            x509.NameAttribute(NameOID.COMMON_NAME, domain),
        ])
        
        # Create certificate
        cert = x509.CertificateBuilder().subject_name(
            subject
        ).issuer_name(
            subject
        ).public_key(
            private_key.public_key()
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.utcnow()
        ).not_valid_after(
            datetime.utcnow() + timedelta(days=days_valid)
        ).add_extension(
            x509.SubjectAlternativeName([
                x509.DNSName(domain),
            ]),
            critical=False,
        ).sign(private_key, hashes.SHA256())
        
        # Serialize certificate and key
        cert_pem = cert.public_bytes(serialization.Encoding.PEM)
        key_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8
        )
        
        return cert_pem.decode(), key_pem.decode(), domain
    
    def generate_env_file(self, build_type: str = "enterprise",
                       database_type: str = "postgresql",
                       domain: str = "your-domain.com") -> str:
        """Generate complete environment file"""
        self.log_header("Generating Complete Environment File")
        
        # Generate all secrets
        server_secret = self.generate_jwt_secret(64)
        db_creds = self.generate_database_credentials(database_type)
        session_secret = self.generate_jwt_secret(32)
        encryption_key, derived_key = self.generate_encryption_key(32)
        webhook_secret = self.generate_webhook_secret(32)
        api_key = self.generate_api_key(64)
        
        # Generate Redis credentials
        redis_password = self.generate_password(16, 24)
        redis_url = f"redis://:{redis_password}@redis:6379"
        
        # Build environment file content
        env_content = f"""# =============================================================================
# AETHER EDGE PRODUCTION CONFIGURATION
# Generated on: {datetime.utcnow().isoformat()} UTC
# Build Type: {build_type}
# Database: {database_type}
# =============================================================================

# =============================================================================
# SECURITY SECRETS (GENERATED)
# =============================================================================
SERVER_SECRET={server_secret}
POSTGRES_PASSWORD={db_creds['password']}
SESSION_SECRET={session_secret}
ENCRYPTION_KEY={encryption_key}
DERIVED_ENCRYPTION_KEY={derived_key}
WEBHOOK_SECRET={webhook_secret}
API_KEY={api_key}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================
DATABASE_URL={db_creds['connection_string']}
REDIS_URL={redis_url}
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_CONNECTION_TIMEOUT=30000

# =============================================================================
# DOMAIN CONFIGURATION
# =============================================================================
DASHBOARD_URL=https://{domain}
DOMAIN_NAME={domain}
ACME_EMAIL=admin@{domain}

# =============================================================================
# BUILD CONFIGURATION
# =============================================================================
BUILD_TYPE={build_type}
DATABASE_TYPE={database_type}
NODE_ENV=production

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================
LOG_LEVEL=info
GERBIL_LOG_LEVEL=info
TRAEFIK_LOG_LEVEL=INFO

# =============================================================================
# FEATURE FLAGS
# =============================================================================
REQUIRE_EMAIL_VERIFICATION=true
DISABLE_SIGNUP_WITHOUT_INVITE=false
DISABLE_USER_CREATE_ORG=false
ALLOW_RAW_RESOURCES=false
ENABLE_INTEGRATION_API=true
ENABLE_CLIENTS=true

# =============================================================================
# PERFORMANCE CONFIGURATION
# =============================================================================
NODE_OPTIONS=--max-old-space-size=4096
CACHE_TTL=3600
CACHE_MAX_SIZE=1000

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=15m
SESSION_TIMEOUT=24h
MAX_FILE_SIZE=10MB
ENABLE_CSP=true
ENABLE_HSTS=true
ENABLE_XSS_PROTECTION=true

# =============================================================================
# BACKUP CONFIGURATION
# =============================================================================
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
"""
        
        return env_content
    
    def analyze_secret(self, secret: str, name: str = "secret") -> None:
        """Analyze and display secret strength"""
        analysis = self.validate_strength(secret, name)
        
        self.log_header(f"Secret Analysis: {name}")
        self.log(f"Length: {analysis['length']}", 'cyan')
        self.log(f"Entropy: {analysis['entropy']:.2f} bits", 'cyan')
        self.log(f"Strength Score: {analysis['strength_score']}/100", 'cyan')
        
        # Character composition
        self.log("Character Composition:", 'cyan')
        self.log(f"  Lowercase: {'✓' if analysis['has_lowercase'] else '✗'}", 'green' if analysis['has_lowercase'] else 'red')
        self.log(f"  Uppercase: {'✓' if analysis['has_uppercase'] else '✗'}", 'green' if analysis['has_uppercase'] else 'red')
        self.log(f"  Digits: {'✓' if analysis['has_digits'] else '✗'}", 'green' if analysis['has_digits'] else 'red')
        self.log(f"  Special: {'✓' if analysis['has_special'] else '✗'}", 'green' if analysis['has_special'] else 'red')
        
        # Issues
        if analysis['common_patterns']:
            self.log("Common Patterns Found:", 'yellow')
            for pattern in analysis['common_patterns']:
                self.log(f"  - {pattern}", 'red')
        
        # Recommendations
        if analysis['recommendations']:
            self.log("Recommendations:", 'yellow')
            for rec in analysis['recommendations']:
                self.log(f"  - {rec}", 'yellow')
        
        # Overall assessment
        if analysis['strength_score'] >= 80:
            self.log("Overall Strength: EXCELLENT", 'green')
        elif analysis['strength_score'] >= 60:
            self.log("Overall Strength: GOOD", 'green')
        elif analysis['strength_score'] >= 40:
            self.log("Overall Strength: FAIR", 'yellow')
        else:
            self.log("Overall Strength: WEAK", 'red')
    
    def save_to_file(self, content: str, filename: str) -> None:
        """Save content to file"""
        try:
            with open(filename, 'w') as f:
                f.write(content)
            self.log(f"Saved to: {filename}", 'green')
        except Exception as e:
            self.log(f"Error saving file: {e}", 'red')

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Aether Edge Advanced Security Generator')
    parser.add_argument('command', choices=[
        'server-secret', 'db-password', 'session-secret', 'api-key',
        'encryption-key', 'webhook-secret', 'password', 'db-connection',
        'ssl-cert', 'rsa-keys', 'env-file', 'analyze', 'all', 'interactive'
    ], help='Command to execute')
    
    # Add arguments for different commands
    parser.add_argument('--length', type=int, default=32, help='Length of generated secret')
    parser.add_argument('--prefix', default='aether', help='Prefix for API key')
    parser.add_argument('--domain', default='your-domain.com', help='Domain name')
    parser.add_argument('--build-type', choices=['oss', 'saas', 'enterprise'], 
                       default='enterprise', help='Build type')
    parser.add_argument('--database', choices=['sqlite', 'postgresql'], 
                       default='postgresql', help='Database type')
    parser.add_argument('--min-length', type=int, default=16, help='Minimum password length')
    parser.add_argument('--max-length', type=int, default=32, help='Maximum password length')
    parser.add_argument('--output', help='Output file name')
    parser.add_argument('--analyze', help='Analyze existing secret')
    
    args = parser.parse_args()
    
    # Check for required dependencies
    try:
        from cryptography import fernet
        from cryptography.hazmat.primitives import hashes
        from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
    except ImportError:
        print("Error: cryptography library is required. Install with: pip install cryptography")
        sys.exit(1)
    
    generator = SecurityGenerator()
    
    try:
        if args.command == 'server-secret':
            secret = generator.generate_jwt_secret(args.length)
            generator.log(secret)
            if args.output:
                generator.save_to_file(secret, args.output)
        
        elif args.command == 'db-password':
            password = generator.generate_password(args.min_length, args.max_length)
            generator.log(password)
            if args.output:
                generator.save_to_file(password, args.output)
        
        elif args.command == 'session-secret':
            secret = generator.generate_jwt_secret(args.length)
            generator.log(secret)
            if args.output:
                generator.save_to_file(secret, args.output)
        
        elif args.command == 'api-key':
            api_key = generator.generate_api_key(args.length, args.prefix)
            generator.log(api_key)
            if args.output:
                generator.save_to_file(api_key, args.output)
        
        elif args.command == 'encryption-key':
            main_key, derived_key = generator.generate_encryption_key(args.length)
            generator.log(f"Main Key: {main_key}")
            generator.log(f"Derived Key: {derived_key}")
            if args.output:
                generator.save_to_file(f"Main: {main_key}\nDerived: {derived_key}", args.output)
        
        elif args.command == 'webhook-secret':
            secret = generator.generate_webhook_secret(args.length)
            generator.log(secret)
            if args.output:
                generator.save_to_file(secret, args.output)
        
        elif args.command == 'password':
            password = generator.generate_password(args.min_length, args.max_length)
            generator.log(password)
            if args.output:
                generator.save_to_file(password, args.output)
        
        elif args.command == 'db-connection':
            creds = generator.generate_database_credentials(args.database)
            generator.log(f"Username: {creds['username']}")
            generator.log(f"Password: {creds['password']}")
            generator.log(f"Connection String: {creds['connection_string']}")
            if args.output:
                generator.save_to_file(creds['connection_string'], args.output)
        
        elif args.command == 'ssl-cert':
            cert, key, domain = generator.generate_ssl_certificate(args.domain)
            generator.log(f"Certificate for {domain} generated")
            if args.output:
                generator.save_to_file(cert, f"{args.output}.crt")
                generator.save_to_file(key, f"{args.output}.key")
        
        elif args.command == 'rsa-keys':
            private_key, public_key = generator.generate_rsa_keys()
            generator.log("RSA Key Pair Generated")
            generator.log("Private Key:", 'cyan')
            generator.log(private_key)
            generator.log("Public Key:", 'cyan')
            generator.log(public_key)
            if args.output:
                generator.save_to_file(private_key, f"{args.output}.private")
                generator.save_to_file(public_key, f"{args.output}.public")
        
        elif args.command == 'env-file':
            env_content = generator.generate_env_file(args.build_type, args.database, args.domain)
            generator.log("Environment file generated")
            if args.output:
                generator.save_to_file(env_content, args.output)
            else:
                generator.save_to_file(env_content, ".env.production")
        
        elif args.command == 'analyze':
            if args.analyze:
                generator.analyze_secret(args.analyze)
            else:
                generator.log("Error: --analyze argument is required for analyze command", 'red')
        
        elif args.command == 'all':
            generator.log_header("Generating All Security Secrets")
            
            secrets = {
                'Server Secret': generator.generate_jwt_secret(64),
                'Database Password': generator.generate_password(24, 32),
                'Session Secret': generator.generate_jwt_secret(32),
                'API Key': generator.generate_api_key(64),
                'Encryption Key': generator.generate_encryption_key(32)[0],
                'Webhook Secret': generator.generate_webhook_secret(32),
                'Password': generator.generate_password(),
            }
            
            for name, value in secrets.items():
                generator.log(f"{name}: {value}", 'cyan')
                generator.analyze_secret(value, name)
                generator.log("")
        
        elif args.command == 'interactive':
            generator.interactive_mode()
    
    except KeyboardInterrupt:
        generator.log("\nOperation cancelled by user", 'yellow')
    except Exception as e:
        generator.log(f"Error: {e}", 'red')
        sys.exit(1)

if __name__ == "__main__":
    main()