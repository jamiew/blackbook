![000000book-handshake](https://000000book.com/images/000000book-handshake.jpg)

# About

**000000book** ("blackbook") is an open repository for sharing and archiving motion captured graffiti tags. Tags are saved as digital text files known as GML (Graffiti Markup Language), which can be captured through freely available software such as [Graffiti Analysis](http://graffitianalysis.com) (marker), [DustTag](http://graffitianalysis.com/iphone) (iPhone), [EyeWriter](http://eyewriter.org) (eye capture), [Laser Tag](http://graffitiresearchlab.com/?page_id=76) (laser).

Graffiti writers are invited to capture and share their own tags, and computer programmers are invited to create new applications and visualizations of the resulting data. The project aims to bring together two seemingly disparate communities that share an interest hacking systems, whether found in code or in the city.

→ Watch: [000000book Intro Video](http://vimeo.com/8072358)

## API

Please visit the [API documentation](http://jamiedubs.com/wikis/blackbook/).

## Team

The GML and **#000000book** development team consists of [Jamie Wilkinson](http://jamiedubs.com),
[Evan Roth](http://evan-roth.com), [Theodore Watson](http://www.theowatson.com),
[Chris Sugrue](http://csugrue.com/) and [Todd Vanderlin](http://toddvanderlin.com/),
all members of the copyleft [F.A.T. Lab](http://fffff.at).

Additional Flash development assistance from [Manolis Perrakis](http://art.manorius.com/)

Contact us: _info[at]000000book.com_

Code available under an MIT License

Copyfree 2009-2023 F.A.T.<br />
"Release early, often & w/ rap music"

![gml-file](https://000000book.com/images/gml-file.png)

---

# Development Setup (Rails 7)

This application has been updated to **Rails 7.1.5** and **Ruby 3.4.5** for modern compatibility.

## Prerequisites

- **Ruby 3.0+** (recommended: 3.4.5 - see `.ruby-version`)
- **Rails 7.1+** (currently 7.1.5)
- **MySQL 5.7+** or **MySQL 8.0+** 
- **Node.js 16+** (for asset compilation)
- **Bundler 2.0+**

### Version Compatibility
This app is fully compatible with:
- Ruby 3.0, 3.1, 3.2, 3.3, 3.4+
- Rails 7.0, 7.1+
- Modern deployment platforms (Heroku, Docker, etc.)

## Getting Started

### 1. Clone and Install Dependencies

```bash
git clone [repository-url]
cd blackbook
bundle install
```

### 2. Database Setup

```bash
# Create and migrate database
bin/rails db:create
bin/rails db:migrate

# Optional: Load sample data
bin/rails db:seed
```

### 3. Credentials Configuration

This app uses Rails encrypted credentials (Rails 7 standard):

```bash
# View current credentials
bin/rails credentials:show

# Edit credentials (opens in $EDITOR)
bin/rails credentials:edit
```

**Important**: The `config/master.key` is auto-generated and should never be committed to git.

#### Current Credentials Structure
```yaml
# Available in credentials:
secret_key_base: [automatically generated]

# Optional AWS configuration (for S3 storage):
aws:
  access_key_id: your_access_key
  secret_access_key: your_secret_key
```

#### Environment Variables
Some configuration can also be set via environment variables:
- `S3_BUCKET` - AWS S3 bucket name for file storage
- `AWS_ACCESS_KEY_ID` - AWS access key (alternative to credentials)  
- `AWS_SECRET_ACCESS_KEY` - AWS secret key (alternative to credentials)

### 4. Start the Application

```bash
# Development server
bin/rails server

# Visit: http://localhost:3000
```

## Data Storage

The application stores data in two places:

1. **Database**: Standard Rails models (users, tags, comments, etc.)
2. **GML Files**: Raw graffiti markup files stored in `/data/` directory
   - Format: `{tag_id}.gml`
   - Managed by `GmlObject` model

## Useful Rake Tasks

### GML Data Management
```bash
# Save all GmlObjects to disk
bin/rails gml_objects:save_to_disk

# Store GmlObjects on IPFS
bin/rails gml_objects:save_to_ipfs

# Fix missing GmlObjects
bin/rails gml_objects:fix_missing
```

### Data Cleanup
```bash
# Find tags with missing data
bin/rails tags:find_missing_data

# Clean up spam users
bin/rails cleanup_spam
```

## Deployment

The application includes a deployment script at `./deploy` that:
- Syncs code from git
- Links production data directory
- Runs migrations
- Compiles assets
- Restarts services

## Rails 7 Migration Notes

This app was recently upgraded from Rails 4.2 to Rails 7.1. Major changes include:

- **Credentials**: Moved from `config/secrets.yml` to encrypted `config/credentials.yml.enc`
- **Strong Parameters**: Added to all controllers
- **Modern Validations**: Updated from `validates_presence_of` to `validates` syntax
- **Asset Pipeline**: Updated for Rails 7 asset handling
- **Turbo**: Replaced Turbolinks with Turbo (Rails 7 default)

## Development Notes

- **No Rails Console in Production**: Use `RAILS_ENV=production bin/rails runner "code here"`
- **Asset Compilation**: `bin/rails assets:precompile` for production
- **Background Jobs**: None currently configured
- **File Uploads**: Uses kt-paperclip gem for image attachments

## Troubleshooting

### Common Issues

**Missing Master Key**
```bash
# If you get "Rails.application.credentials is missing" error:
# The master key should be in config/master.key (gitignored)
# For production, set RAILS_MASTER_KEY environment variable
```

**Database Connection**
```bash
# Check database configuration
cp config/database.yml.example config/database.yml  # if needed
bin/rails db:create
```

**Asset Issues**
```bash
# Clear and recompile assets
bin/rails assets:clobber
bin/rails assets:precompile
```

**GML Data Directory**
```bash
# Create data directory if missing
mkdir -p data
# Check permissions
chmod 755 data
```

## API Documentation

For API usage, see: [API documentation](http://jamiedubs.com/wikis/blackbook/)

