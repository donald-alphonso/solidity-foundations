# solidity-foundations

Apprentissage progressif de Solidity et de l'écosystème Foundry.

## Modules

### M1 — Fondations EVM & Solidity
- **S1** — Counter (ownership, events, custom errors) — coverage 100%
- **S2** — TipJar (payable, msg.value, receive/fallback, withdraw pattern) — coverage 100%

## Stack
- Solidity ^0.8.24
- Foundry (forge, cast, anvil)

## Setup
... (corrige les typos: `forge build`, "custom errors")

## Notes d'apprentissage S2
- `payable` : autorise une fonction à recevoir de l'ETH ; sans ce mot-clé, tout transfert revert.
- `msg.value` : ETH attaché à la tx, en wei. Toujours raisonner en wei.
- `receive()` vs `fallback()` : receive pour ETH pur (calldata vide), fallback pour signature inconnue.
- Pattern `.call{value: x}("")` : envoi d'ETH moderne, forward tout le gas, checker le `success`.
- `tx.origin` ≠ `msg.sender` : ne jamais utiliser `tx.origin` pour l'authentification.