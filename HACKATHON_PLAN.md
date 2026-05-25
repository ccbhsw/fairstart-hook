# FairStart Hook - X Layer Build X Hackathon Plan

## 0. Project In One Sentence

FairStart Hook is a Uniswap v4 launch-phase protection Hook for new pools on X Layer. It combines immutable launch rules, anti-sweep dynamic fees, same-sender cooldown fees, and short-term LP removal locks so new pools can open trading without hidden admin controls.

## 1. Plain Explanation

This is not a new token, a new exchange, or a pitch-only idea.

It is a pool-level "opening protection plugin" for Uniswap v4:

- Normal users can swap as usual.
- Large early buyers pay higher fees.
- Same-wallet repeated swaps pay higher fees.
- Early LPs cannot add liquidity and immediately pull it during the protected launch window.
- Project teams cannot secretly change launch rules after the pool is live.

In simple terms: a new pool gets a public launch rulebook on chain.

## 2. Research Conclusion

The original "generic dynamic fee Hook" idea is too common.

Existing or crowded areas include:

- generic dynamic fee hooks
- volatility-based fee hooks
- MEV-protection hooks
- launchpads and auction launches
- allowlist/compliance hooks
- TWAMM and limit-order hooks

So the project should not be "we adjust the fee when volatility changes".

The stronger angle is:

FairStart is a launch-phase protection Hook for new assets. It protects the first stage of a new pool with transparent, locked rules that are visible to users, LPs, and judges.

## 3. Why This Fits The Hackathon

The hackathon asks for:

- Uniswap v4 Hook logic
- deployment on X Layer
- a real v4 Pool and Hook contract
- verifiable contract addresses
- real Hook behavior triggered by transactions

FairStart fits because:

- It uses `beforeSwap` for dynamic LP fee override.
- It uses `beforeRemoveLiquidity` to enforce early LP commitment.
- It uses `afterInitialize` to start the launch window.
- It emits public events that make judging and demo review easier.
- It targets a real X Layer growth problem: safer launch of new assets, meme tokens, AI-agent assets, game assets, and community tokens.

## 4. MVP Features

Must build:

- `FairStartHook.sol`
- per-pool launch config
- locked launch rules after initialization
- dynamic fee override in `beforeSwap`
- early liquidity-removal lock in `beforeRemoveLiquidity`
- event logs for demo and judging
- Foundry tests
- X Layer deployment scripts
- README and submission docs

Do not build for MVP:

- no complex oracle dependency
- no offchain AI decision engine
- no full frontend requirement
- no hidden admin backdoor

## 5. Fee Rules

The v4 pool must be created with dynamic fees enabled.

Fee table for MVP:

- Base fee: 0.05%
- Launch-window fee: 0.30%
- Same-sender cooldown fee: 0.60%
- Large-swap fee: 1.00%
- Max fee cap: 1.00%

Fee reasons:

- `BASE`: normal swap.
- `LAUNCH_WINDOW`: pool is still in launch protection.
- `COOLDOWN`: same sender swaps again too quickly.
- `LARGE_SWAP`: swap amount is above threshold.

The Hook should prefer fee protection over swap blocking. Blocking swaps feels harsh. Blocking early LP removal is acceptable because it protects the pool's launch promise.

## 6. Contract Design

Main contract:

- `src/FairStartHook.sol`

Hook permissions:

- `afterInitialize`
- `beforeSwap`
- `afterSwap`
- `beforeRemoveLiquidity`

Main structs:

- `PoolConfig`
  - `baseFee`
  - `launchFee`
  - `cooldownFee`
  - `largeSwapFee`
  - `maxFee`
  - `launchDuration`
  - `liquidityLockDuration`
  - `cooldownSeconds`
  - `largeSwapThreshold`
- `PoolState`
  - `launchTimestamp`
  - `swapCount`
  - `rulesLocked`

Main mappings:

- `poolConfig[poolId]`
- `poolState[poolId]`
- `lastSwapAt[poolId][sender]`

Main events:

- `PoolConfigured`
- `LaunchStarted`
- `LaunchRulesLocked`
- `FairStartFeeApplied`
- `LiquidityRemovalBlocked`

Important v4 detail:

- Use Uniswap v4 template or HookMiner so the Hook address has the right permission bits.
- Use `LPFeeLibrary.DYNAMIC_FEE_FLAG` when creating the pool.
- Return `fee | LPFeeLibrary.OVERRIDE_FEE_FLAG` from `beforeSwap`.

## 7. Local Project Structure

Target structure:

```text
.
├── src/
│   └── FairStartHook.sol
├── script/
│   ├── DeployHook.s.sol
│   ├── CreatePool.s.sol
│   └── DemoSwaps.s.sol
├── test/
│   └── FairStartHook.t.sol
├── docs/
│   ├── SUBMISSION.md
│   ├── DEMO_SCRIPT.md
│   └── TWEETS.md
├── foundry.toml
├── README.md
├── RESEARCH.md
└── .env.example
```

## 8. Execution Plan

### Step 1 - Research And Plan

Output:

- `RESEARCH.md`
- `HACKATHON_PLAN.md`

Status:

- Done.

### Step 2 - Dev Environment

Actions:

- Initialize Git repo.
- Set up Foundry.
- Create a Uniswap v4 Hook project skeleton.
- Add `.gitignore` and `.env.example`.

Output:

- Project compiles with placeholder Hook.

### Step 3 - Hook MVP

Actions:

- Implement `FairStartHook.sol`.
- Add pool config and launch lock.
- Add dynamic fee logic.
- Add early LP-removal lock.
- Add events.

Output:

- MVP Hook contract compiles.

### Step 4 - Tests

Actions:

- Test normal swap fee.
- Test launch-window fee.
- Test same-sender cooldown fee.
- Test large-swap fee.
- Test max-fee cap.
- Test liquidity removal blocked during launch lock.
- Test liquidity removal allowed after lock expires.

Output:

- `forge test` passes.

### Step 5 - Deployment Scripts

Actions:

- Add X Layer mainnet config.
- Use official Uniswap v4 X Layer deployments:
  - PoolManager: `0x360e68faccca8ca495c1b759fd9eee466db9fb32`
  - PositionManager: `0xcf1eafc6928dc385a342e7c6491d371d2871458b`
  - StateView: `0x76fd297e2d437cd7f76d50f01afe6160f86e9990`
- Deploy demo tokens if needed.
- Deploy Hook.
- Create v4 Pool with dynamic fee flag.
- Add initial liquidity.

Output:

- Hook address.
- Pool key or pool id.
- Token addresses.
- Deployment transaction hashes.

### Step 6 - Onchain Demo

Actions:

- Run small normal swap.
- Run quick repeated swap.
- Run large swap.
- Attempt early LP removal.
- Capture events and explorer links.

Output:

- Onchain proof that FairStart rules trigger.

### Step 7 - Submission Package

Actions:

- Write README for judges.
- Write `docs/SUBMISSION.md` with addresses and links.
- Write 1-3 minute demo video script.
- Draft X/Twitter posts tagging:
  - `@XLayerOfficial`
  - `@Uniswap`
  - `@flapdotsh`

Output:

- GitHub repo ready.
- X post ready.
- Google Form ready.

## 9. Demo Storyboard

Video length: 1-3 minutes.

Simple structure:

1. Problem: new pools are fragile during launch.
2. Solution: FairStart gives the pool public launch rules.
3. Show code: `beforeSwap` sets dynamic fees.
4. Show code: `beforeRemoveLiquidity` blocks early LP exit.
5. Show X Layer deployment: Hook and Pool.
6. Show demo:
   - normal swap gets low fee
   - repeated swap gets higher fee
   - large swap gets highest fee
   - early LP removal is blocked
7. Close: FairStart helps X Layer builders launch new assets with more trust.

## 10. What Counts As Done

Minimum acceptable submission:

- Hook contract deployed on X Layer.
- v4 Pool initialized with that Hook.
- At least one successful swap calling the Hook.
- At least one event proving FairStart logic triggered.
- README explains the mechanism.
- GitHub repo is public or accessible.
- X/Twitter post is live.
- Google Form submitted before deadline.

Strong submission:

- Multiple swaps showing different fee reasons.
- LP lock demo included.
- Tests passing.
- Clean README with tables.
- Demo video included.
- Explorer links included for every important transaction.

## 11. Risks And Backup Plans

Risk: Foundry setup takes time on Windows.

- Backup: use WSL or a minimal Hardhat setup only if Foundry becomes a blocker.

Risk: X Layer testnet has no v4 deployments.

- Backup: deploy on X Layer mainnet with tiny amounts using official v4 contracts.

Risk: full frontend takes too long.

- Backup: no frontend for MVP. Script plus explorer plus video is enough.

Risk: LP removal hook is hard to test quickly.

- Backup: keep dynamic fee Hook as the minimum, but keep the launch-lock code if it compiles and passes tests.

## 12. Honest Prize View

No one can honestly guarantee a prize.

What we can control:

- real Hook code
- real tests
- real X Layer deployment
- real swap-triggered behavior
- clear differentiation from generic dynamic fee hooks
- clean README and demo video

That is the practical route to a competitive submission.

## 13. References

- Hackathon page: https://web3.okx.com/xlayer/build-x-hackathon/hook
- X Layer network info: https://web3.okx.com/xlayer/docs/developer/build-on-xlayer/network-information
- Uniswap v4 deployments: https://developers.uniswap.org/docs/protocols/v4/deployments
- Uniswap v4 hooks: https://developers.uniswap.org/docs/protocols/v4/concepts/hooks
- Uniswap v4 dynamic fees: https://developers.uniswap.org/docs/protocols/v4/concepts/dynamic-fees
- Uniswap v4 template: https://developers.uniswap.org/docs/community/tooling/v4-template
