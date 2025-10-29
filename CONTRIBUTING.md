# Contributing to Ultimate Linux Optimization Suite

Thank you for your interest in contributing! 🎉

## How to Contribute

### Reporting Issues
- Check if the issue already exists
- Provide system information (distro, RAM, kernel version)
- Include relevant logs from `/var/log/ultimate-optimizer-*.log`
- Describe expected vs actual behavior

### Suggesting Features
- Open an issue with the "enhancement" label
- Explain the use case and benefits
- Provide examples if possible

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Test thoroughly on multiple distributions**
   - Ubuntu/Debian
   - Fedora
   - Arch
   - At least one other distro if possible

4. **Follow existing code style**
   - Use bash best practices
   - Add comments for complex logic
   - Keep functions focused and modular

5. **Submit a Pull Request**
   - Describe what changed and why
   - Reference any related issues
   - Include test results

### Testing Guidelines
- Test on a VM or spare system first
- Verify backup/restore functionality
- Check that existing optimizations aren't broken
- Test with different RAM amounts (2GB, 4GB, 8GB, 16GB+)

### Code Review Process
- Maintainers will review your PR
- Address any feedback or requested changes
- Once approved, your PR will be merged

## Questions?
Open an issue or start a discussion!
