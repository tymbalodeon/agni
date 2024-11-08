# View help text
@help *recipe:
    ../scripts/agni/help.nu {{ recipe }}

# Run using an example score
@example *args:
    #!/usr/bin/env nu
    ../scripts/agni/example.nu {{ args }}
