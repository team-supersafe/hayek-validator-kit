---
description: Measuring revenue-impacting elements of the validator
---

# Performance

## Skipped Leader Slots

## APY

## Income

Income for a validator is measured by epoch. Primary sources of income and expenses vary according to the table below:

<table><thead><tr><th width="356.01171875">Name / Description</th><th width="180.3203125">Who pays it</th><th>When and how is paid</th></tr></thead><tbody><tr><td><strong>Commission</strong>: The percentage of <em><strong>inflation</strong></em> rewards collected by the validator from its stakers as commission for services.</td><td>Stakers</td><td>Per block.<br>Paid to the validator's vote account.</td></tr><tr><td><strong>Transaction Fees (part of Leader Slot Rewards)</strong>: 50% of all standard transaction fees in the block produced.</td><td>Users who submit transactions to the Solana network</td><td>Per block produced.<br>Paid to the validator's identity account.</td></tr><tr><td><strong>Priority Fees (included in Leader Slot Rewards)</strong>: 100% of all priority (CU-based) fees in the transactions that were included in the block produced.</td><td>Users who submit transactions to the Solana network</td><td>Per block produced.<br>Paid to the validator's account of identity.</td></tr><tr><td><strong>Voting Fees</strong>: Also known as vote transaction fees, these are a small cost that validators pay to submit votes to the network.</td><td>Every validator pays this to earn <a href="performance.md#timely-vote-credits-tvc">TVC</a>.</td><td>Per block.<br>Paid from the validator's identity account.</td></tr><tr><td><strong>Voting Compensation</strong>: Offered by the SFDP, this initiative enables smaller or newer validators to remain financially sustainable by offsetting the cost of voting fees.</td><td>Solana Foundation through the SFDP</td><td>Per epoch.<br>Paid to the validator's identity account.</td></tr><tr><td><strong>Jito Rewards</strong>: Only applicable if you are running the Jito-Solana client, which enables MEV tip capture via the Jito Block Engine</td><td>Bots, searchers who want to front-run, back-run, or bundle transactions for arbitrage</td><td>Per block.<br>Paid to the validator's identity account.</td></tr></tbody></table>

## Timely Vote Credits (TVC)

## Commission
