import { queue } from "@trigger.dev/sdk/v3";

export const conversionFree = queue({
  name: "conversion-free",
  concurrencyLimit: 20,
});

export const conversionStarter = queue({
  name: "conversion-starter",
  concurrencyLimit: 20,
});

export const conversionPro = queue({
  name: "conversion-pro",
  concurrencyLimit: 20,
});

export const conversionBusiness = queue({
  name: "conversion-business",
  concurrencyLimit: 20,
});

export const conversionDatarooms = queue({
  name: "conversion-datarooms",
  concurrencyLimit: 20,
});

export const conversionDataroomsPremium = queue({
  name: "conversion-datarooms-premium",
  concurrencyLimit: 20,
});
