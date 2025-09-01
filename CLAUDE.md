# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Server
- `bin/dev` - Start the development server using foreman/overmind (runs Rails server + Vite)
- `bin/rails s` - Start Rails server only
- `bin/vite dev` - Start Vite development server only

**Important**: Do NOT run `bin/dev` or `bin/rails s` - assume the development server is already running. Only use these commands if explicitly asked to start the server.

### Testing
- `bin/rails test` - Run all tests
- `bin/rails test test/models/` - Run model tests
- `bin/rails test test/controllers/` - Run controller tests  
- `bin/rails test test/integration/` - Run integration tests

### Database
- `bin/rails db:setup` - Create, migrate and seed database
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:rollback` - Rollback last migration
- `bin/rails db:reset` - Drop, create, migrate and seed database

### Code Quality
- `bin/rubocop` - Run Ruby linter (configured for Rails omakase)
- `bundle exec brakeman` - Run security scanner

### Email Testing
- `bin/rails "email:test[your-email@example.com]"` - Test email configuration
- `bin/rails "email:test_resend[your-email@example.com]"` - Test Resend API specifically

### Admin Tasks
- `bin/rails "invitations:cleanup"` - Clean up expired invitations
- `bin/rails "reminders:process"` - Send daily payment reminders (runs automatically via SolidQueue)
- `bin/rails "reminders:stats"` - Show reminder system statistics
- `bin/rails "reminders:test[project_id]"` - Test reminder system for a specific project

### Telegram Bot
- `bin/rails telegram:setup_webhook` - Configure webhook for development/production
- `bin/rails telegram:webhook_info` - Check webhook status and configuration
- `bin/rails telegram:remove_webhook` - Remove webhooks
- `bin/rails telegram:reset_webhook` - Reset webhook (remove and setup)
- `bin/rails telegram:test_webhook` - Test webhook endpoint locally
- Bot responds to commands: `/start`, `/help`, `/status`, `/payments`, `/pay`, `/settings`, `/unlink`

## Application Architecture

### Stack Overview
- **Backend**: Ruby on Rails 8.0+ with Inertia.js for frontend integration
- **Frontend**: Svelte 5 with TypeScript, TailwindCSS, and ShadcnUI components
- **Database**: SQLite with SolidCache, SolidQueue, SolidCable for caching/jobs
- **Authentication**: Magic link authentication with bcrypt sessions
- **Build System**: Vite for frontend asset compilation

### Core Domain Models
- **Project**: Main subscription entity with cost splitting logic (`app/models/project.rb:158`)
- **BillingCycle**: Represents billing periods with payment tracking (`app/models/billing_cycle.rb:68`) 
- **Payment**: Individual payment records with evidence uploads
- **User**: Authentication and profile management with magic links and Telegram integration
- **ProjectMembership**: Join table for project access control
- **Invitation**: Email-based invitation system for project members
- **TelegramMessage**: Telegram notification tracking and delivery status

### Key Business Logic
- **Currency Support**: Multi-currency support via `CurrencySupport` concern
- **Billing Frequency**: Configurable billing cycles (daily, weekly, monthly, quarterly, yearly)
- **Cost Splitting**: Automatic per-member cost calculation based on project membership
- **Payment Tracking**: Evidence upload, confirmation workflow, and reminder system
- **Archive Policy**: Automatic archiving of old billing cycles based on configuration

### Frontend Architecture
- **Inertia.js**: Server-driven SPA with Svelte components
- **Layout System**: Multiple layouts (auth, admin, main) in `app/frontend/layouts/`
- **Component Structure**: Reusable UI components in `app/frontend/lib/components/`
- **Routing**: Rails routes with Inertia page components in `app/frontend/pages/`

### Authentication & Authorization
- **Magic Links**: Primary authentication method via `MagicLink` model
- **Sessions**: Managed through `Session` model and `Authentication` concern
- **Authorization**: Role-based access (owner/member) via `Authorization` concern  
- **Admin Access**: HTTP Basic auth for admin routes (`/admin/*`)

### Email System
- **Primary**: Resend API for production email delivery
- **Fallback**: SMTP configuration support
- **Development**: Letter Opener for email preview at `/letter_opener`
- **Templates**: ERB templates in `app/views/*_mailer/` with both HTML and text versions

### Telegram Bot Integration
- **Bot Framework**: telegram-bot-ruby gem for Telegram API integration
- **Account Linking**: Users can link Telegram accounts via verification tokens in profile settings
- **Notifications**: Payment reminders, billing cycle alerts, and payment confirmations via Telegram
- **Bot Commands**: Interactive commands including `/start`, `/help`, `/status`, `/payments`, `/pay`, `/settings`, `/unlink`
- **Services**: `TelegramBotService` for webhook processing, `TelegramNotificationService` for message formatting
- **Jobs**: `TelegramNotificationJob` for asynchronous delivery
- **Models**: `TelegramMessage` for delivery tracking and status
- **Webhooks**: Primary integration method via `TelegramController` at `/telegram/webhook`
- **Routes**: Profile integration routes for token generation, status checking, unlinking, and notification preferences
- **Testing**: Full webhook endpoint testing with mocked service calls

### Background Jobs
- **Queue**: SolidQueue for job processing
- **Billing Jobs**: Automatic billing cycle generation and archiving
- **Reminder Jobs**: Automated payment reminder system
- **Email Jobs**: Asynchronous email delivery
- **Telegram Jobs**: Asynchronous Telegram notification delivery

### File Storage
- **Active Storage**: For payment evidence uploads
- **Security**: Secure file access with token-based downloads
- **Development**: Local storage in `storage/` directory

### Admin Interface
- **Billing Configuration**: Global settings for billing frequencies and policies
- **Error Monitoring**: SolidErrors dashboard at `/admin/errors`
- **Project Management**: Admin oversight of all projects

### Security Features
- **Rate Limiting**: Rails 8 native rate limiting for magic link requests and invitations
- **CSRF Protection**: Standard Rails CSRF tokens
- **Content Security Policy**: Configured CSP headers
- **Parameter Filtering**: Sensitive data excluded from logs
- **Error Handling**: Comprehensive exception handling with notifications
- **Email Verification**: Magic link verification for invitation security
- **Audit Logging**: Security event logging for invitation and authentication flows

### Configuration & Environment
- **Credentials**: Telegram bot token stored in Rails credentials (`telegram_bot_token`)
- **Webhook Secret**: Optional webhook secret token in Rails credentials (`telegram_webhook_secret`)
- **Routes**: Telegram webhook endpoint and profile integration routes in `config/routes.rb`
- **Initializers**: Telegram webhook configuration in `config/initializers/telegram.rb`
- **Development**: Webhook-based integration requiring ngrok for local testing
- **Environment Variables**: 
  - `TELEGRAM_WEBHOOK_URL` for development webhook setup (webhooks auto-enabled when present)
  - Production webhooks are automatically configured using `base_url` from credentials

### Development Tools
- **Letter Opener**: Email preview in development
- **Web Console**: Debugging in development
- **Docker**: Full containerized development and production setup
- **Kamal**: Deployment configuration included

### Testing Strategy
- **Minitest**: Rails default testing framework
- **Fixtures**: Test data in `test/fixtures/`
- **Integration Tests**: Full workflow testing in `test/integration/`
- **Controller Tests**: Including TelegramController webhook endpoint testing
- **Service Tests**: TelegramBotService and TelegramNotificationService testing
- **Authentication Helpers**: `sign_in_as(user)` and `admin_authenticate` helpers

### Documentation
- **Invitation Flow**: Complete documentation in `docs/INVITATION_FLOW_DOCUMENTATION.md`
- **Authentication Flow**: Complete documentation in `docs/AUTHENTICATION_FLOW_DOCUMENTATION.md`
- **Telegram Webhooks**: Complete webhook setup and troubleshooting in `docs/TELEGRAM_WEBHOOKS.md`