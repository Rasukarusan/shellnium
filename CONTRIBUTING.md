# Contributing to Shellnium

Thank you for your interest in contributing to Shellnium!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/<your-username>/shellnium.git`
3. Create a branch: `git checkout -b my-feature`
4. Make your changes
5. Push and open a Pull Request

## Development Setup

```bash
# Start ChromeDriver
chromedriver --port=9515

# Run a demo to verify everything works
bash demo.sh
```

## Code Style

- Quote all variable expansions: `"${var}"` instead of `$var`
- Use `local` for function-scoped variables
- Follow existing naming conventions (snake_case for functions)
- Avoid debug output (no stray `echo` statements)

## Testing

Before submitting a PR, verify your changes work with both `bash` and `zsh`:

```bash
bash demo.sh
zsh demo.sh
```

## Adding New WebDriver Commands

When implementing a new [W3C WebDriver](https://www.w3.org/TR/webdriver/) command:

1. Add the function to the appropriate section in `lib/core.sh`
2. Follow the existing pattern for HTTP method usage (`$GET`, `$POST`, `$DELETE`)
3. Quote all URL variables: `"${BASE_URL}/..."`
4. Update `README.md` with the new method
