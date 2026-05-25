# FairStart Hook

FairStart Hook is a Uniswap v4 launch-phase protection Hook for new pools on X Layer.

It gives a new pool public opening rules:

- normal swaps stay cheap
- large early swaps pay higher fees
- repeated same-wallet swaps pay higher fees
- early LP removal is locked during the launch window
- launch rules are visible on chain and locked after pool initialization

## Why It Matters

New pools are fragile. Early sweeping, repeated bot swaps, and instant liquidity withdrawal can damage a launch before normal users arrive. FairStart moves those launch rules into a Uniswap v4 Hook, so users, LPs, and judges can verify the behavior on chain.

This is not a token tax contract and not an off-chain bot. The rules are pool-level Hook logic.

## Hook Flow

1. A pool is initialized with FairStart Hook and `LPFeeLibrary.DYNAMIC_FEE_FLAG`.
2. `afterInitialize` records launch time and locks the pool's launch rules.
3. `beforeSwap` returns an LP fee override based on launch-window, cooldown, or large-swap rules.
4. `afterSwap` records the actor's last swap time and increments the pool swap counter.
5. `beforeRemoveLiquidity` blocks LP removal until the launch lock expires.

## MVP Fee Table

| Rule | Fee |
| --- | ---: |
| Normal swap | 0.05% |
| Launch-window swap | 0.30% |
| Same-actor cooldown swap | 0.60% |
| Large swap | 1.00% |

## Contract

- Main Hook: [`src/FairStartHook.sol`](./src/FairStartHook.sol)
- Tests: [`test/FairStartHook.t.sol`](./test/FairStartHook.t.sol)
- Deploy script: [`script/00_DeployHook.s.sol`](./script/00_DeployHook.s.sol)

## X Layer Mainnet v4 Addresses

The repo is configured for the official Uniswap v4 deployment on X Layer mainnet:

- Chain ID: `196`
- PoolManager: `0x360e68faccca8ca495c1b759fd9eee466db9fb32`
- PositionManager: `0xcf1eafc6928dc385a342e7c6491d371d2871458b`
- StateView: `0x76fd297e2d437cd7f76d50f01afe6160f86e9990`

## Local Commands

```bash
forge build
forge test
```

Current test status:

```text
14 tests passed, 0 failed
```

## Deployment

Copy `.env.example` to `.env`, then fill `PRIVATE_KEY`.

```bash
forge script script/00_DeployHook.s.sol:DeployHookScript \
  --rpc-url $XLAYER_RPC_URL \
  --broadcast
```

After Hook deployment, create a v4 Pool using `LPFeeLibrary.DYNAMIC_FEE_FLAG`, add liquidity, then run demo swaps.

## Docs

- [Research](./RESEARCH.md)
- [Hackathon Plan](./HACKATHON_PLAN.md)
- [Submission Checklist](./docs/SUBMISSION.md)
- [Demo Script](./docs/DEMO_SCRIPT.md)
- [Tweets](./docs/TWEETS.md)
