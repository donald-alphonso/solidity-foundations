# solidity-foundations

Apprentissage progressif de Solidity et de l'écosystème Foundry.
Module 1, Semaine 1 : Counter étendu avec ownership, events, customs errors.

## Stack
- solidity ^0.8.24
- Foundry (forge, cast, anvil)

## Setup
\`\`\`bash
git clone <repo-url>
cd solidity-foundations
forge install
forge buid
forge test
\`\`\`

## Déploiement local
\`\`\`bash
anvil # terminal 1
forge create src/Counter.sol:Counter --rpc-url http://localhost:8545 --private-key <ANVIL_KEY> --broadcast # terminal 2
\`\`\`

## Coverage
forge coverage -> 85.71%

## Notes d'apprentissage
- immutable : owner -> fixé au constructeur et ne change jamais -> stocké dans le byte code -> moins cher en gaz (const en js)
- indexed sur les event params -> permet de filtrer les logs, côté client (wagmi, ethers, indexeurs) -> Max 3 params indexed par event
- testFuzz_* : Foundry génére 256 inputs aléatoires -> ça trouvre des bugs qu'on ne verrait jamais avec des tests à valeurs fixes.