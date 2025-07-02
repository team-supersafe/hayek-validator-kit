---
description: Measuring revenue-impacting elements of the validator
---

# Performance

## Skipped Leader Slots

## APY

## Income

Income for a validator is measured by epoch. Primary sources of income and expenses vary according to the table below:

<table><thead><tr><th width="356.01171875">Name / Description</th><th width="180.3203125">Who pays it</th><th>When and how is paid</th></tr></thead><tbody><tr><td><mark style="background-color:green;"><strong>Commission</strong></mark>: The percentage of <em><strong>inflation</strong></em> rewards collected by the validator from inflation (SOL created on every epoch) as commission for voting and securing the network.</td><td>Inflationary Rewards as part of a scheduled inflation rate that mints new SOL.</td><td>Per epoch. Rewards for epoch N are paid in the first block of epoch N + 1. Rewards depend on the inflation rate, the validator’s stake-weight (amount of SOL staked to the validator vs. total network stake), the TVC accrued in epoch N and the configured commission.<br><mark style="background-color:green;">Paid to</mark> the validator's vote account.</td></tr><tr><td><mark style="background-color:green;"><strong>Transaction Fees</strong></mark><strong> (part of Leader Slot Rewards)</strong>: 50% of all standard transaction fees in the block produced.</td><td>Users who submit transactions to the Solana network</td><td>Per block produced.<br><mark style="background-color:green;">Paid to</mark> the validator's identity account.</td></tr><tr><td><mark style="background-color:green;"><strong>Priority Fees</strong></mark><strong> (included in Leader Slot Rewards)</strong>: 100% of all priority (CU-based) fees in the transactions that were included in the block produced.</td><td>Users who submit transactions to the Solana network</td><td>Per block produced.<br><mark style="background-color:green;">Paid to</mark> the validator's account of identity.</td></tr><tr><td><mark style="background-color:red;"><strong>Voting Fees</strong></mark>: Also known as vote transaction fees, these are a small cost that validators pay to submit votes to the network as any other Solana transaction.</td><td>Every validator pays this to earn <a href="performance.md#timely-vote-credits-tvc">TVC</a>.</td><td>Per block.<br><mark style="background-color:red;">Paid from</mark> the validator's identity account.</td></tr><tr><td><mark style="background-color:green;"><strong>Voting Compensation</strong></mark>: Offered by the SFDP, this initiative enables smaller or newer validators to remain financially sustainable by offsetting the cost of voting fees.</td><td>Solana Foundation through the SFDP</td><td>Per epoch.<br><mark style="background-color:green;">Paid to</mark> the validator's identity account.</td></tr><tr><td><mark style="background-color:green;"><strong>Jito Rewards</strong></mark>: Only applicable if you are running the Jito-Solana client, which enables MEV tip capture via the Jito Block Engine</td><td>Bots, searchers who want to front-run, back-run, or bundle transactions for arbitrage</td><td>Per block.<br><mark style="background-color:green;">Paid to</mark> the validator's identity account.</td></tr></tbody></table>

## Timely Vote Credits (TVC)

## Commission
