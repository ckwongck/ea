//+------------------------------------------------------------------+
//|                                          ck_EMA_ATR_highLowRange |
//|                                           Copyright 2020, ckwong |
//|                                 https://github.com/ckwong1204/ea |
//+------------------------------------------------------------------+
#property copyright "ck 2020-12-20"
#property link "http://www.mql4.com"
#property description "Moving Average sample expert advisor"

#define MAGICMA 20201220


class TrailOrder{
   public: 
   int action;
   double holdingOrderPrice;
   double trailHighLowPrice;
   double trailAmount;
   int positions;

   TrailOrder(){}
   void resetTrailValues() {
      action = NULL;
      holdingOrderPrice = 0;
      trailHighLowPrice = 0;
      trailAmount = 0;
      positions = 0;
   }
   void setTrailValues(double i_price, double i_trailAmount) {
      holdingOrderPrice = i_price;
      trailHighLowPrice = i_price;
      trailAmount = i_trailAmount;
      positions = 1;
   }
   void addPosition() {
      positions++;
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
void buyOrderSendWithTlSp(double price, double takeProfit, double stopLoss) {
   // double takeProfit = 0; //price + takeProfitRatio * atr;
   // double stopLoss = 0;   //price - stopLossRatio * atr;
   const string comment = "long" + stopLoss + "-" + takeProfit;

   int ticket = OrderSend(Symbol(), OP_BUY, getLots(), price, 3, stopLoss, takeProfit, comment, MAGICMA, 0, Green);

   if (ticket > 0) {
      if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
         Print("buy order opened : ", OrderOpenPrice());
   } else
      Print("Error opening BUY order : ", GetLastError());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellOrderSendWithTlSp(double price, double takeProfit, double stopLoss) {
   // double takeProfit = 0; //price - takeProfitRatio * atr;
   // double stopLoss = 0;   //price + stopLossRatio * atr;
   string comment = "short" + stopLoss + "-" + takeProfit;

   int ticket = OrderSend(Symbol(), OP_SELL, getLots(), price, 3, stopLoss, takeProfit, comment, MAGICMA, 0, Red);

   if (ticket > 0) {
      if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
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


/*input*/ double Lots = 0.01;
/*input*/ int atrPeriod = 14;
/*input*/ int MovingShift = 1;
/*input*/ int emaPeriod20 = 14;
/*input*/ int emaPeriod50 = 28;
/*input*/ int emaPeriod70 = 112;
/*input*/ int emaCriteriaContinousCount = 14; //bars
/*input*/ int highLowRangePeriod = 8;         //hour
/*input*/ double stopLossRatio = 3.5;
/*input*/ double takeProfitRatio = 2 * stopLossRatio;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
//--- check for history and trading
   if (Bars < atrPeriod || IsTradeAllowed() == false)
      return;

//--- calculate open orders by current symbol
   int positions = calculateCurrentOrders(Symbol());
   double currentPrice = Close[0];
   if (positions == 0) {
      double ema20_s1 = iMA(NULL, PERIOD_H1, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 1);
      double ema50_s1 = iMA(NULL, PERIOD_H1, emaPeriod50, MovingShift, MODE_EMA, PRICE_CLOSE, 1);
      double ema70_s1 = iMA(NULL, PERIOD_H1, emaPeriod70, MovingShift, MODE_EMA, PRICE_CLOSE, 1);
      
      double ema20_s3 = iMA(NULL, PERIOD_H1, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 12);
      double ema50_s3 = iMA(NULL, PERIOD_H1, emaPeriod50, MovingShift, MODE_EMA, PRICE_CLOSE, 12);
      double ema70_s3 = iMA(NULL, PERIOD_H1, emaPeriod70, MovingShift, MODE_EMA, PRICE_CLOSE, 12);

      double ema20_s5 = iMA(NULL, PERIOD_H1, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 28);
      double ema50_s5 = iMA(NULL, PERIOD_H1, emaPeriod50, MovingShift, MODE_EMA, PRICE_CLOSE, 28);
      double ema70_s5 = iMA(NULL, PERIOD_H1, emaPeriod70, MovingShift, MODE_EMA, PRICE_CLOSE, 28);

      double ema20_1H = iMA(NULL, PERIOD_H4, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 1);
      double ema20_3H = iMA(NULL, PERIOD_H4, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 3);
      double ema20_5H = iMA(NULL, PERIOD_H4, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 5);

      double ema20_1W = iMA(NULL, PERIOD_W1, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 1);
      double ema20_2W = iMA(NULL, PERIOD_W1, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 2);
      double ema20_3W = iMA(NULL, PERIOD_W1, emaPeriod20, MovingShift, MODE_EMA, PRICE_CLOSE, 3);

      double atr = iATR(NULL, PERIOD_H1, atrPeriod, MovingShift);
      double periodHigh = iHigh(NULL, PERIOD_H1, iHighest(NULL, PERIOD_H1, MODE_HIGH, highLowRangePeriod, 1)) + 1 * atr;
      double periodLow = iLow(NULL, PERIOD_H1, iLowest(NULL, PERIOD_H1, MODE_LOW, highLowRangePeriod, 1)) + 1 * atr;

      bool ema_gt_criteria_s1 = ema20_s1 >= ema50_s1 && ema50_s1 >= ema70_s1;
      bool ema_gt_criteria_s3 = ema20_s3 >= ema50_s3 && ema50_s3 >= ema70_s3;
      bool ema_gt_criteria_s5 = ema20_s5 >= ema50_s5 && ema50_s5 >= ema70_s5;

      bool ema_lt_criteria_s1 = ema20_s1 <= ema50_s1 && ema50_s1 <= ema70_s1;
      bool ema_lt_criteria_s3 = ema20_s3 <= ema50_s3 && ema50_s3 <= ema70_s3;
      bool ema_lt_criteria_s5 = ema20_s5 <= ema50_s5 && ema50_s5 <= ema70_s5;

      bool ema_shift_growth_H1_up = ema20_s1 >= ema20_s3 && ema20_s3 >= ema20_s5;
      bool ema_shift_growth_H1_down = ema20_s1 <= ema20_s3 && ema20_s3 <= ema20_s5;

      bool ema_shift_growth_H4_up = ema20_1H >= ema20_3H && ema20_3H >= ema20_5H;
      bool ema_shift_growth_H4_down = ema20_1H <= ema20_3H && ema20_3H <= ema20_5H;

      bool ema_shift_growth_W_up = ema20_1W >= ema20_2W && ema20_2W >= ema20_3W;
      bool ema_shift_growth_W_down = ema20_1W <= ema20_2W && ema20_2W <= ema20_3W;

      // bool ATR細過180Range_20% =

      bool buyCondition = currentPrice > periodHigh 
                            // && emaCountCriteria.isBuy(ema_gt_criteria_s1) 
                            && ema_gt_criteria_s1
                            && ema_gt_criteria_s3
                            && ema_gt_criteria_s5
                            // && ema_shift_growth_H1_up 
                            // && ema_shift_growth_H4_up 
                            // && ema_shift_growth_W_up
                            ;  //&& atr < 0.0015; currentPrice>ema20;
      bool sellCondition = currentPrice < periodLow
                            // && emaCountCriteria.isSell(ema_lt_criteria) 
                            && ema_lt_criteria_s1
                            && ema_lt_criteria_s3
                            && ema_lt_criteria_s5
                            // && ema_shift_growth_H1_down 
                            // && ema_shift_growth_H4_down 
                            // && ema_shift_growth_W_down
                            ; //&& atr < 0.0003; currentPrice<ema20;

      if (buyCondition) {
         buyOrderSendWithTlSp(Ask, 0, 0);
         trailOrder.setTrailValues(Ask, stopLossRatio * atr); // trail
      } 
      // else if (sellCondition) {
      //    sellOrderSendWithTlSp(Bid, 0, 0);
      //    trailOrder.setTrailValues(OP_SELL, Bid, stopLossRatio * atr); // trail
      // }
   }
   else if (positions > 0) {
      // long position
      if (currentPrice >= trailOrder.holdingOrderPrice + trailOrder.trailAmount * (1 - trailOrder.positions/2)) {
         closeAllPosition();
      } 
      else if (currentPrice < trailOrder.holdingOrderPrice - trailOrder.trailAmount * trailOrder.positions) {
         buyOrderSendWithTlSp(Ask, 0, 0);
         trailOrder.addPosition();
      }
   } 
   // else {
   //    // positions < 0   // short position
   //    if (currentPrice > trailOrder.trailHighLowPrice + trailOrder.trailAmount) {
   //       closeAllPosition();
   //    } else if (currentPrice < trailOrder.trailHighLowPrice) {
   //       trailOrder.trailHighLowPrice = currentPrice;
   //    }
   // }
}
//+------------------------------------------------------------------+


