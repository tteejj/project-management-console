/**
 * EconomySystem.ts
 * Comprehensive economy simulation with supply/demand dynamics
 */

import { SpaceStation, StationFaction } from './StationGenerator';

export interface Commodity {
  id: string;
  name: string;
  category: 'FUEL' | 'FOOD' | 'MINERALS' | 'TECH' | 'LUXURY' | 'INDUSTRIAL';
  basePrice: number;        // credits per unit
  volume: number;           // m³ per unit
  illegal: boolean;
  perishable: boolean;
  productionDifficulty: number; // 0-1
}

export interface MarketData {
  commodity: string;
  supply: number;           // units available
  demand: number;           // units wanted
  price: number;            // current price
  priceHistory: number[];   // last 10 prices
  volatility: number;       // 0-1 (price change rate)
}

export interface TradeRoute {
  from: string;             // station ID
  to: string;               // station ID
  commodity: string;
  profitMargin: number;     // credits per unit
  volume: number;           // units per day
  distance: number;         // light years
  risk: number;             // 0-1
}

export interface EconomicZone {
  stations: SpaceStation[];
  production: Map<string, number>;  // commodity -> units/day
  consumption: Map<string, number>; // commodity -> units/day
  prices: Map<string, number>;      // commodity -> price
  gdp: number;                      // total economic output
}

/**
 * All available commodities
 */
export const COMMODITIES: Map<string, Commodity> = new Map([
  ['fuel', {
    id: 'fuel',
    name: 'Hydrogen Fuel',
    category: 'FUEL',
    basePrice: 100,
    volume: 0.1,
    illegal: false,
    perishable: false,
    productionDifficulty: 0.3
  }],
  ['oxygen', {
    id: 'oxygen',
    name: 'Oxygen',
    category: 'FUEL',
    basePrice: 50,
    volume: 0.1,
    illegal: false,
    perishable: false,
    productionDifficulty: 0.2
  }],
  ['water', {
    id: 'water',
    name: 'Water',
    category: 'FOOD',
    basePrice: 20,
    volume: 0.05,
    illegal: false,
    perishable: false,
    productionDifficulty: 0.1
  }],
  ['food', {
    id: 'food',
    name: 'Food Supplies',
    category: 'FOOD',
    basePrice: 150,
    volume: 0.2,
    illegal: false,
    perishable: true,
    productionDifficulty: 0.5
  }],
  ['iron', {
    id: 'iron',
    name: 'Iron Ore',
    category: 'MINERALS',
    basePrice: 80,
    volume: 0.5,
    illegal: false,
    perishable: false,
    productionDifficulty: 0.4
  }],
  ['rare_earth', {
    id: 'rare_earth',
    name: 'Rare Earth Elements',
    category: 'MINERALS',
    basePrice: 500,
    volume: 0.1,
    illegal: false,
    perishable: false,
    productionDifficulty: 0.8
  }],
  ['uranium', {
    id: 'uranium',
    name: 'Uranium',
    category: 'FUEL',
    basePrice: 800,
    volume: 0.05,
    illegal: false,
    perishable: false,
    productionDifficulty: 0.9
  }],
  ['electronics', {
    id: 'electronics',
    name: 'Electronics',
    category: 'TECH',
    basePrice: 300,
    volume: 0.1,
    illegal: false,
    perishable: false,
    productionDifficulty: 0.7
  }],
  ['medicine', {
    id: 'medicine',
    name: 'Medical Supplies',
    category: 'TECH',
    basePrice: 400,
    volume: 0.05,
    illegal: false,
    perishable: true,
    productionDifficulty: 0.8
  }],
  ['weapons', {
    id: 'weapons',
    name: 'Weapons',
    category: 'INDUSTRIAL',
    basePrice: 600,
    volume: 0.2,
    illegal: true,
    perishable: false,
    productionDifficulty: 0.7
  }],
  ['luxury_goods', {
    id: 'luxury_goods',
    name: 'Luxury Goods',
    category: 'LUXURY',
    basePrice: 1000,
    volume: 0.1,
    illegal: false,
    perishable: false,
    productionDifficulty: 0.9
  }],
  ['contraband', {
    id: 'contraband',
    name: 'Contraband',
    category: 'LUXURY',
    basePrice: 2000,
    volume: 0.05,
    illegal: true,
    perishable: false,
    productionDifficulty: 0.5
  }]
]);

/**
 * Economy simulator
 */
export class EconomySystem {
  private stations: Map<string, SpaceStation> = new Map();
  private markets: Map<string, Map<string, MarketData>> = new Map(); // stationId -> commodity -> data
  private tradeRoutes: TradeRoute[] = [];
  private economicZones: EconomicZone[] = [];

  /**
   * Register a station in the economy
   */
  registerStation(station: SpaceStation): void {
    this.stations.set(station.id, station);
    this.initializeMarket(station);
  }

  /**
   * Initialize market for a station
   */
  private initializeMarket(station: SpaceStation): void {
    const market = new Map<string, MarketData>();

    for (const [commodityId, commodity] of COMMODITIES) {
      // Determine supply and demand based on station type
      const { supply, demand } = this.calculateSupplyDemand(station, commodity);

      // Calculate price based on supply/demand
      const price = this.calculatePrice(commodity.basePrice, supply, demand);

      market.set(commodityId, {
        commodity: commodityId,
        supply,
        demand,
        price,
        priceHistory: [price],
        volatility: commodity.category === 'LUXURY' ? 0.3 : 0.1
      });
    }

    this.markets.set(station.id, market);
  }

  /**
   * Calculate supply and demand for a commodity at a station
   */
  private calculateSupplyDemand(
    station: SpaceStation,
    commodity: Commodity
  ): { supply: number; demand: number } {
    const population = station.population;
    const baseSupply = 100;
    const baseDemand = 100;

    let supply = baseSupply;
    let demand = baseDemand;

    // Station type affects production/consumption
    switch (station.stationType) {
      case 'TRADING_HUB':
        supply *= 5; // Lots of goods
        demand *= 3; // High turnover
        break;

      case 'MINING_PLATFORM':
        if (commodity.category === 'MINERALS') {
          supply *= 10; // Produces minerals
          demand *= 0.5;
        } else if (commodity.category === 'FOOD') {
          supply *= 0.1;
          demand *= 5; // Needs food
        }
        break;

      case 'FUEL_DEPOT':
        if (commodity.category === 'FUEL') {
          supply *= 20; // Produces fuel
          demand *= 0.3;
        }
        break;

      case 'RESEARCH_FACILITY':
        if (commodity.category === 'TECH') {
          supply *= 3;
          demand *= 2;
        }
        if (commodity.category === 'LUXURY') {
          demand *= 0.5; // Low demand
        }
        break;

      case 'MILITARY_BASE':
        if (commodity.id === 'weapons') {
          supply *= 5;
        }
        if (commodity.category === 'FOOD') {
          demand *= 3;
        }
        break;

      case 'SHIPYARD':
        if (commodity.category === 'INDUSTRIAL' || commodity.category === 'MINERALS') {
          demand *= 10; // Needs materials
        }
        break;
    }

    // Population affects demand
    demand *= (population / 10000);

    // Faction affects availability
    if (commodity.illegal) {
      if (station.faction === 'PIRATE') {
        supply *= 5; // Pirates have contraband
      } else if (station.faction === 'UNITED_EARTH' || station.faction === 'MARS_FEDERATION') {
        supply *= 0.1; // Restricted
        demand *= 0.1;
      }
    }

    // Wealth affects luxury demand
    if (commodity.category === 'LUXURY') {
      demand *= station.economy.wealthLevel * 2;
    }

    return { supply, demand };
  }

  /**
   * Calculate price based on supply and demand
   */
  private calculatePrice(
    basePrice: number,
    supply: number,
    demand: number
  ): number {
    // Price = basePrice * (demand / supply)
    // But clamped to reasonable range

    const ratio = demand / Math.max(supply, 1);

    let priceMultiplier: number;
    if (ratio > 2.0) {
      // High demand, low supply - expensive
      priceMultiplier = 1.5 + Math.min(ratio - 2, 3) * 0.5;
    } else if (ratio < 0.5) {
      // Low demand, high supply - cheap
      priceMultiplier = 0.5 + ratio * 0.5;
    } else {
      // Normal
      priceMultiplier = 0.5 + ratio * 0.5;
    }

    return basePrice * priceMultiplier;
  }

  /**
   * Update economy simulation
   */
  update(deltaTime: number): void {
    // Update each station's market
    for (const [stationId, market] of this.markets) {
      for (const [commodityId, data] of market) {
        // Simulate production and consumption
        const station = this.stations.get(stationId)!;
        const commodity = COMMODITIES.get(commodityId)!;

        // Production
        let production = 0;
        if (station.economy.supplyGoods.includes(commodity.name)) {
          production = data.supply * 0.01 * (deltaTime / 86400); // 1% per day
        }

        // Consumption
        let consumption = 0;
        if (station.economy.demandGoods.includes(commodity.name)) {
          consumption = data.demand * 0.01 * (deltaTime / 86400); // 1% per day
        }

        // Update supply
        data.supply += production - consumption;
        data.supply = Math.max(0, data.supply);

        // Price adjustment based on supply change
        const oldPrice = data.price;
        data.price = this.calculatePrice(commodity.basePrice, data.supply, data.demand);

        // Track price history
        if (data.priceHistory.length >= 10) {
          data.priceHistory.shift();
        }
        data.priceHistory.push(data.price);

        // Update volatility
        const priceChange = Math.abs(data.price - oldPrice) / oldPrice;
        data.volatility = data.volatility * 0.9 + priceChange * 0.1;
      }
    }

    // Update trade routes
    this.updateTradeRoutes();
  }

  /**
   * Find profitable trade routes
   */
  private updateTradeRoutes(): void {
    this.tradeRoutes = [];

    const stationList = Array.from(this.stations.values());

    for (let i = 0; i < stationList.length; i++) {
      for (let j = i + 1; j < stationList.length; j++) {
        const station1 = stationList[i];
        const station2 = stationList[j];

        // Calculate distance
        const dx = station1.position.x - station2.position.x;
        const dy = station1.position.y - station2.position.y;
        const dz = station1.position.z - station2.position.z;
        const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
        const distanceLY = distance / 9.461e15;

        // Check each commodity
        for (const commodityId of COMMODITIES.keys()) {
          const market1 = this.markets.get(station1.id)!.get(commodityId)!;
          const market2 = this.markets.get(station2.id)!.get(commodityId)!;

          // Route from 1 to 2
          if (market1.supply > market2.supply && market1.price < market2.price) {
            const profitMargin = market2.price - market1.price;
            const volume = Math.min(market1.supply, market2.demand) * 0.1; // 10% of available

            if (profitMargin > 10 && volume > 0) {
              this.tradeRoutes.push({
                from: station1.id,
                to: station2.id,
                commodity: commodityId,
                profitMargin,
                volume,
                distance: distanceLY,
                risk: this.calculateTradeRisk(station1, station2, commodityId)
              });
            }
          }

          // Route from 2 to 1
          if (market2.supply > market1.supply && market2.price < market1.price) {
            const profitMargin = market1.price - market2.price;
            const volume = Math.min(market2.supply, market1.demand) * 0.1;

            if (profitMargin > 10 && volume > 0) {
              this.tradeRoutes.push({
                from: station2.id,
                to: station1.id,
                commodity: commodityId,
                profitMargin,
                volume,
                distance: distanceLY,
                risk: this.calculateTradeRisk(station2, station1, commodityId)
              });
            }
          }
        }
      }
    }

    // Sort by profitability
    this.tradeRoutes.sort((a, b) => {
      const profitA = a.profitMargin * a.volume / (a.distance + 1);
      const profitB = b.profitMargin * b.volume / (b.distance + 1);
      return profitB - profitA;
    });
  }

  /**
   * Calculate risk for a trade route
   */
  private calculateTradeRisk(
    from: SpaceStation,
    to: SpaceStation,
    commodityId: string
  ): number {
    let risk = 0.1; // Base risk

    const commodity = COMMODITIES.get(commodityId)!;

    // Illegal goods are risky
    if (commodity.illegal) {
      risk += 0.5;
    }

    // Pirate stations are risky
    if (from.faction === 'PIRATE' || to.faction === 'PIRATE') {
      risk += 0.3;
    }

    // Distance increases risk
    const dx = from.position.x - to.position.x;
    const dy = from.position.y - to.position.y;
    const dz = from.position.z - to.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
    const distanceLY = distance / 9.461e15;

    risk += Math.min(0.3, distanceLY * 0.05);

    return Math.min(1.0, risk);
  }

  /**
   * Execute a trade
   */
  executeTrade(
    stationId: string,
    commodityId: string,
    amount: number,
    buying: boolean
  ): { success: boolean; price: number; total: number } {
    const market = this.markets.get(stationId);
    if (!market) return { success: false, price: 0, total: 0 };

    const data = market.get(commodityId);
    if (!data) return { success: false, price: 0, total: 0 };

    const commodity = COMMODITIES.get(commodityId)!;

    if (buying) {
      // Buying from station
      if (data.supply < amount) {
        return { success: false, price: data.price, total: 0 };
      }

      data.supply -= amount;
      data.demand += amount * 0.1; // Buying increases future demand

      // Price increases slightly due to reduced supply
      data.price *= (1 + amount / data.supply * 0.1);

      return {
        success: true,
        price: data.price,
        total: data.price * amount
      };
    } else {
      // Selling to station
      if (data.demand < amount * 0.5) {
        return { success: false, price: data.price * 0.5, total: 0 }; // Low demand, low price
      }

      data.supply += amount;
      data.demand = Math.max(0, data.demand - amount * 0.5);

      // Price decreases slightly due to increased supply
      data.price *= (1 - amount / data.supply * 0.1);
      data.price = Math.max(commodity.basePrice * 0.1, data.price);

      return {
        success: true,
        price: data.price,
        total: data.price * amount
      };
    }
  }

  /**
   * Get current price for a commodity at a station
   */
  getPrice(stationId: string, commodityId: string): number {
    const market = this.markets.get(stationId);
    if (!market) return 0;

    const data = market.get(commodityId);
    return data?.price || 0;
  }

  /**
   * Get market data for a station
   */
  getMarket(stationId: string): Map<string, MarketData> | undefined {
    return this.markets.get(stationId);
  }

  /**
   * Get profitable trade routes
   */
  getTopTradeRoutes(limit: number = 10): TradeRoute[] {
    return this.tradeRoutes.slice(0, limit);
  }

  /**
   * Get all commodity definitions
   */
  getAllCommodities(): Commodity[] {
    return Array.from(COMMODITIES.values());
  }
}
