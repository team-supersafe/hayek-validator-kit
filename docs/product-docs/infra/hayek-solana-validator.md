# Hayek Solana Validator

The Hayek Solana Validator uses the Hayek Validator Kit for infrastructure and security using the Jito installer.

<table><thead><tr><th width="177.60546875">Name</th><th>Mainnet</th><th>Testnet</th></tr></thead><tbody><tr><td>Identity Public Key</td><td>hykfH9jUQqe2yqv3VqVAK5AmMYqrmMWmdwDcbfsm6My</td><td>hyt8ZV8sweXyxva1S9tibC4iTaixfFfx8icpGXtNDUJ</td></tr><tr><td>Voting Public Key</td><td>HAYEKSWg2EY21k38St9X5yM7QMW6SunKDefs5SqYSFty</td><td>HYtDsj1sa5fFzy6osKuP9WHPPDhwRYBwqCMpxbzTJeSg</td></tr></tbody></table>

### Validator Upgrade Policy

Hayek Validator client software gets upgraded when any of these triggers are true:

1. The minimum cluster recommended by SF is higher (check this [Discord Channel](https://discord.com/channels/428295358100013066/669406841830244375))
2. The version required by SFDP is higher (check [Delegation Criteria](https://solana.org/delegation-criteria), or the SVT dashboard [HERE](https://svt.one/analytics/HAYEKSWg2EY21k38St9X5yM7QMW6SunKDefs5SqYSFty))
3. When our rankings are affected due to outdated version ([Stakewiz](https://stakewiz.com/validator/HAYEKSWg2EY21k38St9X5yM7QMW6SunKDefs5SqYSFty), [Edgevana](https://stake.edgevana.com/validators/details/HAYEKSWg2EY21k38St9X5yM7QMW6SunKDefs5SqYSFty), [Jito](https://www.jito.network/stakenet/steward/HAYEKSWg2EY21k38St9X5yM7QMW6SunKDefs5SqYSFty/), etc)

Additionally, there's a dependency on the Jito client that needs to be available for the update (See both [Discord](https://discord.com/channels/938287290806042626/1148261936086142996) and [GitHub](https://github.com/jito-foundation/jito-solana/releases) channels for details). This is a pre-requisite to upgrade, since we depend on Jito to publish the Jito mod for the specific Agave version.
