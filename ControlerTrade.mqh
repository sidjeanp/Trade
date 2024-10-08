/*
  ControlerTrade.mqh
  CopyRight 2024, Sidjeanp
  https://www.sidjeanp.com
*/
#property copyright "CopyRight 2024, Sidjeanp"
#property link      "https://www.sidjeanp.com"
#property version   "1.00"

#include <Sidjeanp/Bot/Utils.mqh>
#include <Sidjeanp/Bot/basicTrade.mqh>

class CControlerTrade : public CBasicTrade{
private:

  void AddOrderList(ulong orderTicket, ENUM_POSITION_TYPE tipo, double pPrice, string pSymbol);
  bool ValidaOrders();
  void listarPositionsOpen();
  void listarOrdersOpen();
  
  void BreakEven(double preco);

protected:
   MPositions listaPositions[];
   MPositions listaHistorico[];
   MPositions listaOrders[];
   
   double beStopGain;
   string beTrigger;
   double beStopLoss;
   

   virtual bool OperarCompra(string msg) override;
   virtual bool OperarVenda(string msg) override;    
  

public:
   CControlerTrade();
   ~CControlerTrade();
   
   int getTotalOrders();
   int getTotalpositions();  
   void AtualizaListas(); 
   virtual void OnTickEvent() override;
   virtual void OnOrderEvent(int order, int eventCode, int orderType, int position, double price, double volume, int slip, int tradeRetcode, string tradeRetcodeDescription);
};

CControlerTrade::CControlerTrade(){
}

CControlerTrade::~CControlerTrade(){
}

void CControlerTrade::AddOrderList(ulong orderTicket, ENUM_POSITION_TYPE tipo, double pPrice, string pSymbol) {
    int index = ArraySize(listaOrders);
    ArrayResize(listaOrders, index + 1);

    // Preenche os campos da nova entrada na lista
    listaOrders[index].position = orderTicket;
    listaOrders[index].type = tipo;
    listaOrders[index].price = pPrice;
    listaOrders[index].symbol = pSymbol;
    listaOrders[index].pFaixa = 0;


    // Adiciona a nova entrada à lista
    listaOrders[index].openTime = TimeCurrent(); // Ou obtenha o tempo de abertura de outra fonte, se necessário
}


bool CControlerTrade::OperarCompra(string msg) {
    bool vRetorno = false;

    if(CBasicTrade::OperarCompra(msg)){
      vRetorno = true;
      AddOrderList(trade.ResultOrder(),POSITION_TYPE_BUY,trade.ResultPrice(),symbol);
      
    }

    return vRetorno;
}

bool CControlerTrade::OperarVenda(string msg) {
    bool vRetorno = false;

    if(CBasicTrade::OperarVenda(msg)){
      vRetorno = true;
      AddOrderList(trade.ResultOrder(),POSITION_TYPE_SELL,trade.ResultPrice(),symbol);      
    }

    return vRetorno;
}

bool CControlerTrade::ValidaOrders(){
  for(int i = 0; i < ArraySize(listaOrders);i++){
    if(OrderGetTicket(listaOrders[i].order)<=0){
      ArrayRemove(listaOrders,i);
      
      int index = ArraySize(listaOrders);
      ArrayResize(listaOrders, index+ 1);      
      return true;          
    }
  }
  return false;
}

void CControlerTrade::OnTickEvent(){
  CBasicTrade::OnTickEvent();//herança
}

void CControlerTrade::listarPositionsOpen(){
  listaPositionsPadrao(listaPositions, symbol, magicNum);
} 


void CControlerTrade::listarOrdersOpen(){
  listaOrdersPadrao(listaOrders, symbol, magicNum);
} 

void CControlerTrade::AtualizaListas(){
  listarOrdersOpen();
  listarPositionsOpen();
}

int CControlerTrade::getTotalOrders(){
  return ArraySize(listaOrders);
}

int CControlerTrade::getTotalpositions(){
  return ArraySize(listaPositions);
}


