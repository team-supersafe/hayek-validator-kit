# Ansible Codebase Health Check - Reusable Prompt

## Quick Analysis Command

Use this prompt whenever you want to run a comprehensive health check on your Ansible codebase:

```text
Please run a comprehensive Ansible codebase health check focusing on:

1. **Variable Propagation Analysis**:
   - Trace variable flow through playbooks → roles → shared tasks
   - Check meta dependencies variable passing
   - Identify missing variable validation
   - Find inconsistent variable patterns

2. **Role Architecture Review**:
   - Analyze role dependencies and meta relationships
   - Check for circular dependencies
   - Validate role reusability patterns
   - Identify potential role consolidation opportunities

3. **Task and Handler Analysis**:
   - Review task idempotency
   - Check handler usage patterns
   - Identify potential task optimization
   - Validate error handling

4. **Inventory and Variable Management**:
   - Analyze group_vars and host_vars usage
   - Check variable precedence conflicts
   - Identify missing variable documentation
   - Find hardcoded values that should be variables

5. **Security and Best Practices**:
   - Check for sensitive data exposure
   - Validate privilege escalation patterns
   - Review conditional logic
   - Identify potential race conditions

6. **Maintainability Assessment**:
   - Check for code duplication
   - Analyze naming conventions
   - Review documentation completeness
   - Identify technical debt

Provide a detailed report with:
- Critical issues (must fix)
- Important improvements (should fix)
- Nice-to-have enhancements (could fix)
- Specific code examples and fixes
- Implementation priority recommendations
```

## Detailed Analysis Command

For a more thorough analysis, use this expanded prompt:

```text
Please conduct a comprehensive Ansible codebase health check with the following detailed analysis:

### 1. Variable Propagation Deep Dive
- Map all variable sources (playbook, group_vars, host_vars, role vars, meta deps)
- Trace variable flow through each role and shared task
- Identify variables that are undefined or potentially undefined
- Check variable validation patterns across roles
- Analyze variable precedence conflicts
- Find missing variable documentation

### 2. Role Architecture Analysis
- Map role dependencies and meta relationships
- Identify potential circular dependencies
- Check role reusability and modularity
- Analyze role complexity and coupling
- Review role naming conventions
- Identify opportunities for role consolidation

### 3. Task and Handler Review
- Check task idempotency patterns
- Analyze handler usage and triggers
- Review conditional logic complexity
- Identify potential task optimization
- Check error handling and failure recovery
- Validate task naming conventions

### 4. Inventory and Variable Management
- Analyze group_vars and host_vars structure
- Check for variable naming conflicts
- Identify missing variable defaults
- Review variable documentation
- Check for hardcoded values
- Analyze variable scope and inheritance

### 5. Security and Best Practices
- Check for sensitive data in plain text
- Review privilege escalation patterns
- Analyze conditional security logic
- Check for potential injection vulnerabilities
- Review file permissions and ownership
- Validate SSL/TLS configurations

### 6. Performance and Optimization
- Identify potential performance bottlenecks
- Check for unnecessary tasks or loops
- Analyze file transfer patterns
- Review caching strategies
- Check for resource-intensive operations

### 7. Maintainability Assessment
- Check for code duplication
- Analyze naming conventions consistency
- Review documentation completeness
- Identify technical debt
- Check for deprecated patterns
- Analyze complexity metrics

### 8. Testing and Validation
- Check for missing precheck tasks
- Review assertion patterns
- Analyze error message quality
- Check for proper failure handling
- Review validation completeness

Provide a comprehensive report with:
- Executive summary of findings
- Critical issues with specific fixes
- Important improvements with implementation details
- Nice-to-have enhancements
- Code examples for all recommendations
- Implementation priority matrix
- Testing strategies for fixes
- Rollback plans for critical changes
```

## Quick Health Check Command

For a rapid assessment, use this minimal prompt:

```text
Run a quick Ansible health check focusing on:
1. Variable propagation issues
2. Missing variable validation
3. Critical role dependencies
4. Security concerns
5. Major maintainability issues

Provide specific fixes with code examples.
```

## Usage Instructions

### When to Run

- **Before major releases** (detailed analysis)
- **Monthly maintenance** (quick health check)
- **After significant changes** (focused analysis)
- **When adding new roles** (architecture review)

### How to Use

1. Copy the appropriate prompt above
2. Paste it into your AI assistant
3. Point to your Ansible codebase directory
4. Review the analysis results
5. Prioritize fixes based on the report
6. Implement fixes incrementally
7. Re-run analysis after significant changes

### Expected Output

- **Executive Summary**: High-level findings
- **Critical Issues**: Must-fix problems with code examples
- **Important Improvements**: Should-fix issues with implementation details
- **Enhancements**: Nice-to-have improvements
- **Implementation Plan**: Prioritized action items
- **Testing Strategy**: How to validate fixes

## Customization Tips

### For Specific Focus Areas

- **Variables only**: "Focus on variable propagation and validation"
- **Security only**: "Focus on security and best practices"
- **Performance only**: "Focus on performance and optimization"
- **Architecture only**: "Focus on role architecture and dependencies"

### For Different Scopes

- **Single role**: "Analyze only the [role_name] role"
- **Specific playbook**: "Focus on [playbook_name] and its roles"
- **Variable flow**: "Trace variables through [specific_path]"

## Integration with CI/CD

Consider adding this analysis to your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Ansible Health Check
  run: |
    # Run AI analysis on codebase
    # Generate health check report
    # Fail if critical issues found
```

This way, you get regular automated health checks as part of your development process.
