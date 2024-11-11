import { toHex } from "viem";

// Replace this value with the symbol you want to register
const tippingSymbol = "$TIP";
const hash = toHex(tippingSymbol).substring(2);

console.log(`
    Use this value when calling the register method:
    ${hash}

    example 
    bytes memory tippingSymbol = hex"${hash}"
`);
