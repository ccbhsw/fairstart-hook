# Submission Checklist

## Project

- Name: FairStart Hook
- Category: Uniswap v4 Hook, DeFi infrastructure, launch protection
- Chain: X Layer
- One-liner: FairStart Hook gives new Uniswap v4 pools public launch rules: dynamic anti-sweep fees, same-actor cooldown fees, and early LP removal locks.

## Links To Fill After Deployment

- GitHub: https://github.com/ccbhsw/fairstart-hook
- X/Twitter account:
- Announcement tweet:
- Demo video:
- Hook contract:
- PoolManager:
- Pool key / pool id:
- Token0:
- Token1:
- Pool initialization tx:
- Initial liquidity tx:
- Normal swap tx:
- Cooldown swap tx:
- Large swap tx:
- Blocked liquidity-removal tx:

## X Layer Mainnet

- Chain ID: `196`
- RPC: `https://rpc.xlayer.tech`
- Explorer: `https://www.okx.com/web3/explorer/xlayer`
- PoolManager: `0x360e68faccca8ca495c1b759fd9eee466db9fb32`
- PositionManager: `0xcf1eafc6928dc385a342e7c6491d371d2871458b`
- StateView: `0x76fd297e2d437cd7f76d50f01afe6160f86e9990`

## Minimum Evidence

- Hook contract deployed on X Layer.
- v4 Pool initialized with this Hook.
- At least one successful swap calling the Hook.
- At least one emitted `FairStartFeeApplied` event.
- Liquidity lock behavior shown by transaction or test.
- README and source code public.

## Google Form Notes

Core mechanism:

FairStart Hook protects new Uniswap v4 pools during launch. It locks launch rules at initialization, applies dynamic LP fee overrides before swaps, records swap activity after swaps, and blocks early LP removal during the configured launch window.

Why it matters:

X Layer needs safer ways to launch new assets. FairStart helps token, meme, AI-agent, game, and community assets open trading with transparent on-chain rules instead of hidden admin controls or off-chain bots.
