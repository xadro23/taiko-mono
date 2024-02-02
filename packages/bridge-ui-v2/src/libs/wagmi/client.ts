import { walletConnect } from '@wagmi/connectors';
import { createConfig, getPublicClient, http } from '@wagmi/core';

import { PUBLIC_WALLETCONNECT_PROJECT_ID } from '$env/static/public';
import { chains } from '$libs/chain';

const projectId = PUBLIC_WALLETCONNECT_PROJECT_ID;

export const publicClient = async (chainId: number) => {
  return await getPublicClient(config, { chainId });
};

const transports = chains.reduce((acc, chain) => {
  //@ts-ignore
  acc[chain.id] = http();
  return acc;
});

export const config = createConfig({
  //@ts-ignore
  chains: [...chains],
  connectors: [walletConnect({ projectId })],
  transports,
});
