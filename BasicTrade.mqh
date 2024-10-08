/*
  BasicTrade.mqh
  CopyRight 2024, Sidjeanp
  https://www.sidjeanp.com
*/
#property copyright "CopyRight 2024, Sidjeanp"
#property link      "https://www.sidjeanp.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

class CBasicTrade{
private:

protected:
   CTrade trade;
   
   string symbol;
   ENUM_TIMEFRAMES period;
   double lote;  
   ulong magicNum;
   
   MqlTick ultimoTick;
   datetime tempoAtual;
   
   MqlDateTime DateTimeStructure;
   
   virtual bool OperarCompra(string msg);
   virtual bool OperarVenda(string msg);
   virtual bool FecharOperacao(ulong pPosition);
   virtual void OnTickEvent();
   
   void CarregarOrdens();
   void CarregarPositions();
   void AtualizaUltimoTick();
   void AtualizaTime();

public:
   CBasicTrade();
   ~CBasicTrade();
};

CBasicTrade::CBasicTrade(){
}

CBasicTrade::~CBasicTrade(){
}

void CBasicTrade::OnTickEvent(){
  AtualizaUltimoTick();
  AtualizaTime();
}

bool CBasicTrade::OperarCompra(string msg){
   bool vRetorno = false;
   
   if(trade.Buy(lote, symbol,0,0,0,"Bot Compra")){
      Print("Ordem de compra padrão sem falha. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
      vRetorno = true;;
   }
   else{
      Print("Ordem de compra padrão com falha. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
      vRetorno = false;
   }
   
   return vRetorno;
}

bool CBasicTrade::OperarVenda(string msg){
   bool vRetorno = false;
   
   if(trade.Sell(lote, symbol,0,0,0,"Bot Venda")){
      Print("Ordem de Venda padrão sem falha. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
      vRetorno = true;;
   }
   else{
      Print("Ordem de Venda padrão com falha. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
      vRetorno = false;
   }
   
   return vRetorno;
}

bool CBasicTrade::FecharOperacao(ulong pPosition){
  return trade.PositionClose(pPosition);
}


void CBasicTrade::CarregarOrdens() {
    // Obtém o número total de ordens
    int totalOrders = PositionsTotal();
    
    // Percorre todas as ordens
    for (int i = 0; i < totalOrders; ++i) {
        // Obtém informações sobre a ordem atual
        if (PositionSelect(i)) {
            // Verifica se a ordem está aberta
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY || PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                // Faça o que você precisa com as informações da ordem, por exemplo:
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                double volume = PositionGetDouble(POSITION_VOLUME);
                double price = PositionGetDouble(POSITION_PRICE_OPEN);
                string type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
                
                // Aqui você pode armazenar as informações da ordem em uma lista, imprimi-las, etc.
                Print("Order Ticket: ", ticket, " | Type: ", type, " | Volume: ", volume, " | Price: ", price);
            }
        }
    }
}

void CBasicTrade::CarregarPositions() {
    // Obtém o número total de posições
    int totalPositions = PositionsTotal();
    
    // Percorre todas as posições
    for (int i = 0; i < totalPositions; ++i) {
        // Seleciona a posição atual
        if (PositionSelectByTicket(i)) {
            // Faça o que você precisa com as informações da posição, por exemplo:
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
            double priceCurrent = PositionGetDouble(POSITION_PRICE_CURRENT);
            string type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
            
            // Aqui você pode armazenar as informações da posição em uma lista, imprimi-las, etc.
            Print("Position Ticket: ", ticket, " | Type: ", type, " | Volume: ", volume, " | Price Open: ", priceOpen, " | Price Current: ", priceCurrent);
        }
    }
}

void CBasicTrade::AtualizaUltimoTick() {
  if(!SymbolInfoTick(symbol,ultimoTick)){
    Print("Erro ao obter informações de preço.");
    return;
  } 
}

void CBasicTrade::AtualizaTime(){
   tempoAtual = TimeCurrent();
   TimeToStruct(tempoAtual,DateTimeStructure); 
}