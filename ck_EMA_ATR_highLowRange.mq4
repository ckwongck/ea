//+------------------------------------------------------------------+
//|                                          ck_EMA_ATR_highLowRange |
//|                                           Copyright 2020, ckwong |
//|                                 https://github.com/ckwong1204/ea |
//+------------------------------------------------------------------+
#property copyright "ck 2020-12-20"
#property link "http://www.mql4.com"
#property description "Moving Average sample expert advisor"

#define MAGICMA 20201220
/*input*/ double Lots = 0.01;
/*input*/ int atrPeriod = 48;
/*input*/ int MovingShift = 1;
/*input*/ int emaPeriod20 = 24;
/*input*/ int emaPeriod50 = 48;
/*input*/ int emaPeriod70 = 144;
/*input*/ int emaCriteriaContinousCount = 24; //bars
/*input*/ int highLowRangePeriod = 8;         //hour
/*input*/ double stopLossRatio = 3.5;
/*input*/ double takeProfitRatio = 2 * stopLossRatio;

class TrailOrder{
   public: 
   double holdingOrderPrice;
   double trailHighLowPrice;
   double trailAmount;

   TrailOrder(){}
   void resetTrailValues() {
      holdingOrderPrice = 0;
      trailHighLowPrice = 0;
      trailAmount = 0;
   }
   void setTrailValues(double i_price, double i_trailAmount) {
      holdingOrderPrice = i_price;
      trailHighLowPrice = i_price;
      trailAmount = i_trailAmount;
   }
};

class EmaCountCriteria{
   public:
   int ema_gt_criteria_count;
   int ema_lt_criteria_count;

   EmaCountCriteria(){
      ema_gt_criteria_count = 0;
      ema_lt_criteria_count = 0;
   }

   bool isBuy(bool ema_gt_criteria) {
      if (ema_gt_criteria) {
         ema_gt_criteria_count++;
      } else {
         ema_gt_criteria_count = 0;
      }
      return ema_gt_criteria_count >= emaCriteriaContinousCount;
   }

   bool isSell(bool ema_lt_criteria) {
      if (ema_lt_criteria) {
         ema_lt_criteria_count++;
      } else {
         ema_lt_criteria_count = 0;
      }
      return ema_lt_criteria_count >= emaCriteriaContinousCount;
   }
};

TrailOrder trailOrder ();
EmaCountCriteria emaCountCriteria ();

static double ema20, ema50, ema70, atr;
static double currentPrice = 0;

//| Calculate open positions
int calculateCurrentOrders(string symbol) {
   int buys = 0, sells = 0;
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
         break;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA) {
         if (OrderType() == OP_BUY)
            buys++;
         if (OrderType() == OP_SELL)
            sells++;
      }
   }
   if (buys > 0)
      return (buys);
   else
      return (-sells);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLots() {
   return 0.01;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void buyOrderSendWithTlSp(double price, double stopLossAmount) {
   double takeProfit = 0; //price + takeProfitRatio * atr;
   double stopLoss = 0;   //price - stopLossRatio * atr;
   const string comment = "long" + stopLoss + "-" + takeProfit;

   int ticket = OrderSend(Symbol(), OP_BUY, getLots(), price, 3, stopLoss, takeProfit, comment, MAGICMA, 0, Green);

   if (ticket > 0) {
      if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
         trailOrder.setTrailValues(price, stopLossAmount); // trail
      Print("buy order opened : ", OrderOpenPrice());
   } else
      Print("Error opening BUY order : ", GetLastError());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellOrderSendWithTlSp(double price, double stopLossAmount) {
   double takeProfit = 0; //price - takeProfitRatio * atr;
   double stopLoss = 0;   //price + stopLossRatio * atr;
   string comment = "short" + stopLoss + "-" + takeProfit;

   int ticket = OrderSend(Symbol(), OP_SELL, getLots(), price, 3, stopLoss, takeProfit, comment, MAGICMA, 0, Red);

   if (ticket > 0) {
      if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
         trailOrder.setTrailValues(price, stopLossAmount); // trail
      Print("sell order opened : ", OrderOpenPrice());
   } else
      Print("Error opening BUY order : ", GetLastError());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllPosition() {
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
         break;
      if (OrderMagicNumber() != MAGICMA || OrderSymbol() != Symbol())
         continue;

      if (OrderType() == OP_BUY) {
         if (!OrderClose(OrderTicket(), OrderLots(), Bid, 3, White)) {
            Print("OrderClose error ", GetLastError());
         }
      } else if (OrderType() == OP_SELL) {
         if (!OrderClose(OrderTicket(), OrderLots(), Ask, 3, White)) {
            Print("OrderClose error ", GetLastError());
         }
      }
   }
   trailOrder.resetTrailValues();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
//--- check for history and trading
   if (Bars < atrPeriod || IsTradeAllowed() == false)
      return;

//--- calculate open orders by current symbol
   int positions = calculateCurrentOrders(Symbol());
   currentPrice = Close[0];
   if (positions == 0) {
      ema20 = iMA(NULL, PERIOD_CURRENT, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 1);
      ema50 = iMA(NULL, PERIOD_CURRENT, emaPeriod50, MovingShift, MODE_EMA, PRICE_CLOSE, 1);
      ema70 = iMA(NULL, PERIOD_CURRENT, emaPeriod70, MovingShift, MODE_EMA, PRICE_CLOSE, 1);

      atr = iATR(NULL, PERIOD_CURRENT, atrPeriod, MovingShift);
      double periodHigh = iHigh(NULL, PERIOD_CURRENT, iHighest(NULL, PERIOD_CURRENT, MODE_HIGH, highLowRangePeriod, 1)) + 1 * atr;
      double periodLow = iLow(NULL, PERIOD_CURRENT, iLowest(NULL, PERIOD_CURRENT, MODE_LOW, highLowRangePeriod, 1)) + 1 * atr;

      bool ema_gt_criteria = ema20 >= ema50 && ema50 >= ema70;
      bool ema_lt_criteria = ema20 <= ema50 && ema50 <= ema70;

      // bool ATR細過180Range_20% =

      bool buyCondition = currentPrice > periodHigh && emaCountCriteria.isBuy(ema_gt_criteria);  //&& atr < 0.0015; currentPrice>ema20;
      bool sellCondition = currentPrice < periodLow && emaCountCriteria.isSell(ema_lt_criteria); //&& atr < 0.0003; currentPrice<ema20;

      if (buyCondition) {
         buyOrderSendWithTlSp(Ask, stopLossRatio * atr);
      } else if (sellCondition) {
         sellOrderSendWithTlSp(Bid, stopLossRatio * atr);
      }
   } else if (positions > 0) {
      // long position
      if (currentPrice < trailOrder.trailHighLowPrice - trailOrder.trailAmount) {
         closeAllPosition();
      } else if (currentPrice > trailOrder.trailHighLowPrice) {
         trailOrder.trailHighLowPrice = currentPrice;
      }
   } else {
      // positions < 0   // short position
      if (currentPrice > trailOrder.trailHighLowPrice + trailOrder.trailAmount) {
         closeAllPosition();
      } else if (currentPrice < trailOrder.trailHighLowPrice) {
         trailOrder.trailHighLowPrice = currentPrice;
      }
   }
}
//+------------------------------------------------------------------+


