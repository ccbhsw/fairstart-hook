# Demo Video Script

Target length: 1-3 minutes.

## 1. Problem

New pools are fragile. Early large buyers, repeated bot swaps, and instant liquidity withdrawal can damage a launch before normal users arrive.

## 2. Solution

FairStart Hook is a Uniswap v4 Hook for X Layer that gives a new pool public opening rules.

Normal swaps stay cheap. Large swaps and repeated same-wallet swaps pay higher fees. Early LP removal is blocked during the launch lock.

## 3. Code Walkthrough

Show `src/FairStartHook.sol`.

- `afterInitialize` records launch time and locks rules.
- `beforeSwap` returns the dynamic LP fee override.
- `afterSwap` records the actor's last swap time.
- `beforeRemoveLiquidity` blocks early LP removal.

## 4. Onchain Walkthrough

Show:

- Hook address
- v4 Pool / Pool key
- X Layer explorer
- normal swap transaction
- cooldown or large-swap transaction
- liquidity-removal lock evidence

## 5. Close

FairStart helps X Layer builders launch new assets with transparent pool-level protection instead of hidden token taxes or off-chain bots.
