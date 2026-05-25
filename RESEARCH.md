# X Layer Hook Hackathon Research

Date: 2026-05-25

## 1. Official Requirement Summary

Source: https://web3.okx.com/xlayer/build-x-hackathon/hook

Key points:

- Project must be built around the Uniswap v4 Hook mechanism.
- Project must be deployed on X Layer.
- At least one v4 Pool and Hook contract must be deployed on X Layer mainnet or testnet.
- Submission must include verifiable contract addresses.
- A dedicated X/Twitter account is required.
- Submission post must tag `@XLayerOfficial`, `@Uniswap`, and `@flapdotsh`.
- Demo video is optional but recommended, 1-3 minutes.
- Judging focuses on innovation, market potential, completion, code quality, onchain data, and whether Hook behavior can be triggered by real transactions.

Practical conclusion:

This is not a pitch-only competition. A real deployed Hook plus a real v4 Pool is the minimum bar.

## 2. X Layer Technical Facts

Source: https://web3.okx.com/xlayer/docs/developer/build-on-xlayer/network-information

X Layer mainnet:

- Chain ID: 196
- RPC: `https://rpc.xlayer.tech`
- Backup RPC: `https://xlayerrpc.okx.com`
- Symbol: OKB
- Explorer: `https://www.okx.com/web3/explorer/xlayer`

X Layer testnet:

- Chain ID: 1952
- RPC: `https://testrpc.xlayer.tech/terigon`
- Backup RPC: `https://xlayertestrpc.okx.com/terigon`
- Symbol: OKB
- Explorer: `https://www.okx.com/web3/explorer/xlayer-test`

## 3. Uniswap v4 Deployment Facts

Source: https://developers.uniswap.org/docs/protocols/v4/deployments

Uniswap v4 is deployed on X Layer mainnet, chain ID 196.

Useful addresses:

- PoolManager: `0x360e68faccca8ca495c1b759fd9eee466db9fb32`
- PositionManager: `0xcf1eafc6928dc385a342e7c6491d371d2871458b`
- StateView: `0x76fd297e2d437cd7f76d50f01afe6160f86e9990`
- Quoter: `0x8928074ca1b241d8ec02815881c1af11e8bc5219`
- Universal Router: `0xda00ae15d3a71466517129255255db7c0c0956d3`
- Permit2: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

Practical conclusion:

Mainnet deployment is viable. If testnet does not have v4 deployments, we can deploy to X Layer mainnet with tiny amounts.

## 4. v4 Hook Technical Boundary

Sources:

- https://developers.uniswap.org/docs/protocols/v4/concepts/hooks
- https://developers.uniswap.org/docs/protocols/v4/concepts/dynamic-fees
- https://developers.uniswap.org/docs/protocols/v4/guides/hooks/getting-started
- https://developers.uniswap.org/docs/community/tooling/v4-template

Important facts:

- A Hook is an external contract attached to a v4 pool.
- Each pool can have one Hook, and one Hook can serve many pools.
- Hooks can run before/after initialization, liquidity changes, swaps, and donations.
- `beforeSwap` can return a dynamic LP fee override when the pool is created with dynamic fees enabled.
- Dynamic fee capability is set at pool creation and cannot be changed after pool creation.
- Uniswap Foundation recommends the Foundry-based `v4-template` for building hooks.
- The v4 template includes example hooks, test setup, deploy scripts, and HookMiner for CREATE2 permission-bit address mining.

Practical conclusion:

Use `v4-template` and implement a Hook with:

- `afterInitialize`
- `beforeSwap`
- `afterSwap`
- `beforeRemoveLiquidity`

This gives us more differentiation than a pure fee Hook.

## 5. Existing Hook Landscape

Sources:

- https://hookatlas.com/hooks
- https://arrakis.finance/blog/the-arrakis-pro-hook-dynamic-fees-for-token-issuers-on-uniswap-v4
- https://docs.aegis.markets/
- https://dynamicfee.v4hooks.dev/
- https://developers.uniswap.org/docs/liquidity/liquidity-launchpad/overview
- https://github.com/Uniswap/v4-hooks-public
- https://github.com/Uniswap/hooklist

Observed crowded areas:

- Generic dynamic fee hooks.
- Volatility-based fee hooks.
- MEV-protection hooks.
- Launchpads and auction-based token launches.
- Compliance or allowlist hooks.
- TWAMM hooks.
- Limit order hooks.
- Wrapping/routing hooks.

Examples:

- Arrakis Pro Hook: dynamic fees for token issuers, with volatility and inventory management.
- Aegis DFM: dynamic fees based on volatility and surge states.
- DynamicFee demo: size-based LP fee override.
- Doppler and Uniswap Liquidity Launchpad: auction-style liquidity bootstrapping.
- Clanker/Flaunch: social or creator token launch primitives.
- Angstrom: MEV-resistant DEX/order sequencing.
- Uniswap official hook repo: wrapping/routing hooks such as WETH and wstETH.

Practical conclusion:

Pure "dynamic fee" is not enough. "Generic launchpad" is also crowded. We need a narrower, concrete, buildable Hook that covers a real pain point and can be demonstrated on chain.

## 6. Recommended Positioning After Research

Revised project name:

**FairStart Hook**

One-sentence description:

FairStart Hook is a Uniswap v4 launch-phase protection Hook for new pools on X Layer. It combines immutable launch rules, short-term LP removal lock, anti-sweep swap fees, same-sender cooldown fees, and public protection events so new assets can open trading without relying on hidden admin controls.

Plain Chinese version:

给新池子开业前一段时间装一个公开透明的保护规则：普通人可以买卖，大户扫货和机器人连刷成本更高，早期 LP 不能刚加完就秒撤，项目方也不能临时改成坑人税。

## 7. Why FairStart Is Better Than The Original "Guarded Launch Hook"

Original idea:

- Mostly dynamic swap fees.

Problem:

- Too many existing hooks already do dynamic fees.

Revised idea:

- Launch lifecycle protection, not just fee calculation.
- Combines swap protection and liquidity-removal protection.
- Makes admin controls boring and transparent by locking launch parameters.
- Can be explained with a practical story: "new pool opening protection".

Differentiators:

- Launch phase expires automatically.
- LP removal is blocked during the configured launch lock.
- Same-wallet cooldown is tracked on chain.
- Large trade surcharge is applied on chain.
- Protection events are emitted for AI/human judging and demo readability.
- No oracle required for MVP, reducing integration risk.

## 8. MVP Feature Set

Must-have:

- `afterInitialize`: register launch timestamp and immutable launch config.
- `beforeSwap`: calculate dynamic LP fee override.
- `afterSwap`: update per-pool swap counters and public state.
- `beforeRemoveLiquidity`: block liquidity removal during the launch lock window.
- Events that clearly show fee reason:
  - `LaunchStarted`
  - `FairStartFeeApplied`
  - `LiquidityRemovalBlocked`
  - `LaunchRulesLocked`

Fee reasons:

- `BASE`: normal fee.
- `LAUNCH_WINDOW`: pool is still in early launch window.
- `COOLDOWN`: same sender trades again too quickly.
- `LARGE_SWAP`: swap amount is above the configured threshold.

MVP fee table:

- Base fee: 0.05%
- Launch fee: 0.30%
- Cooldown fee: 0.60%
- Large swap fee: 1.00%
- Max fee cap: 1.00%

Must-not-have for MVP:

- No complex oracle dependency.
- No offchain AI decision maker.
- No frontend as a hard dependency.
- No admin backdoor to change launch fee after lock.

## 9. Stretch Features

Only after MVP:

- Simple dashboard page reading contract events.
- Volatility surcharge from internal price movement.
- Public launch-score view function.
- One-click demo script outputting a judge-friendly table.
- Hooklist submission metadata.

## 10. Practical Build Route

1. Set up Foundry and Uniswap v4 template.
2. Rename example Hook to `FairStartHook`.
3. Implement launch config and immutable pool settings.
4. Implement dynamic fee override in `beforeSwap`.
5. Implement LP removal lock in `beforeRemoveLiquidity`.
6. Write tests for all launch-phase rules.
7. Deploy to X Layer mainnet or testnet.
8. Create a v4 Pool with dynamic fee flag and the Hook address.
9. Run demo swaps and one blocked liquidity-removal demo.
10. Write README, demo script, X post, and submission file.

## 11. Decision

Recommended path:

Build **FairStart Hook**, not a generic dynamic fee Hook.

Reason:

It is more differentiated, more understandable, easier to demo, and still realistic to finish before the deadline.
