//+------------------------------------------------------------------+
//|                                                    BotMoving.mq5 |
//|                                                     SidneiSantos |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#property copyright "sidjeanp"
#property version "0.01"


#include <Trade\Trade.mqh>
CTrade trade;

#define PANEL_NAME "BotMoving - First"

input int mediaPeriodo1 = 8;//Período da média 1
input ENUM_MA_METHOD ma_metodo1 = MODE_EMA;//Método Média 1
input ENUM_APPLIED_PRICE ma_preco1 = PRICE_CLOSE;//Preço para média 1

input int mediaPeriodo2 = 55;//Período da média 2
input ENUM_MA_METHOD ma_metodo2 = MODE_EMA;//Método Média 2
input ENUM_APPLIED_PRICE ma_preco2 = PRICE_CLOSE;//Preço para média 2

input int mediaPeriodo3 = 0;//Período da média 3
input ENUM_MA_METHOD ma_metodo3 = MODE_EMA;//Método Média 3
input ENUM_APPLIED_PRICE ma_preco3 = PRICE_CLOSE;//Preço para média 3

input ENUM_ORDER_TYPE_FILLING preenchimento = ORDER_FILLING_RETURN;

input double lote = 0.01;//Lote
input double stopLoss = 20.0;//Stop Loss
input double takeProfit = 400.0;//Take Profit
input double zonaNotOpe = 5;//Zona sem operação
input ulong magicNum = 123456;//Magic Number
input ulong desvPts = 7;//Desvio em pontos
input double spredMax = 30;//Spred máximo

input bool   bHabCompas = true;//Habilita compras
input bool   bHabVendas = true;//Habilita vendas
input int    operacaoPorCandle = 1;// Operações por candle

input double beTrigger = 300;//BeakEven Start
input double beStopLoss = 50;//BeakEven Stop
input double beStopGain = 400;//BeakEven Take Profit

input double trlTrigger = 200;//Trailling Start
input double trlStopLoss = 50;//Trailling Stop
input double stepTS = 2;//Trailling Step

input string opDias = "0;1;2;3;4;5;6";//Dias da semana que opera
input string opHorario = "00:00:00-23:59:59";//Horário de operação
input string opDiasHorarios ;//Dias e horários de operação "0-00:00:00-23:59:59;-;6-00:00:00-23:59:59"


MqlTick ultimoTick;
MqlRates rates[];

double mediaArray1[];
double mediaArray2[];
double mediaArray3[];

int mediaHandle1;
int mediaHandle2;
int mediaHandle3;

bool posAberta;
bool ordPendente;
bool beAtivo;
bool orientacaoOpBuy;
bool opeInZone;
bool operar;
double spread;

double PRC; //
double BD;
double STL;
double TKP;

string diasParaOperacao[];

struct MPositions{
   ulong                         order;            // Order ticket
   ulong                         position;         // Position ticket
   double                        price;            // Price
   ENUM_POSITION_TYPE            type;             // Order type
   datetime                      openTime;         // Data hora abertura
   datetime                      closeTime;         // Data hora abertura
 };
 
struct MDiasHoras{
  string dia;
  string inicio;
  string fim;
};
 
MPositions listaPositions[];
MPositions listaOrders[];
MDiasHoras horasParaOperacao[];

datetime lastCandleTime = 0;
datetime currentCandleTime;
datetime tempoAtual;
MqlDateTime DateTimeStructure;
int tempoEntreOperacoes = PeriodSeconds() / operacaoPorCandle;

void OnDeinit(const int reason){
}   


int OnInit(){  
      
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
  if(!SymbolInfoTick(_Symbol,ultimoTick)){
    Print("Erro ao obter informações de preço.");
    return;
  }
  //Comment("Preço ASK = ",ultimoTick.ask, "\n Preço BID = ",ultimoTick.bid);
  tempoAtual = TimeCurrent();
  TimeToStruct(tempoAtual,DateTimeStructure);
  
  
 
  operar = false;
  int buySell = -1; 
  //spread = SymbolInfoDouble(_Symbol, SYMBOL_SPREAD); 

  if(CopyBuffer(mediaHandle1,0,0,3,mediaArray1)<0){
    Print("Erro ao copiar dados da média móvel: ", GetLastError());
  }
  if(CopyBuffer(mediaHandle2,0,0,3,mediaArray2)<0){
    Print("Erro ao copiar dados da média móvel: ", GetLastError());
  }
  if(CopyRates(_Symbol,_Period,0,3,rates)<0){
    Print("Erro ao obter as informações de MqlRates: ", GetLastError());
  }
  
  ordPendente = false;
  for(int i = OrdersTotal()-1; i>=0; i--){
    ulong ticket = OrderGetTicket(i);
    ulong positionTicket = PositionGetTicket(i);
    if(!PositionSelectByTicket(positionTicket)){
      Print("Falha ao selecionar o ticket");
    }    
    string symbol = OrderGetString(ORDER_SYMBOL);
    ulong magic = OrderGetInteger(ORDER_MAGIC);
    if(symbol==_Symbol && magic==magicNum){
      ordPendente = true;
      break;
    }
  }    
  
  buySell = -1;
  if((mediaArray1[0]-(zonaNotOpe*_Point)>mediaArray2[0]) && (mediaArray1[2]+(zonaNotOpe*_Point)<mediaArray2[2]) &&
     (spread <= spredMax)){
    buySell = 0;//Fazer compra
    //if(rates[1].close>rates[1].open){
      if(mediaArray1[0]-(zonaNotOpe*_Point)>mediaArray2[0]){
        operar = true;
      }
      else{
        opeInZone = true;      
      }      
    //}    
  }
  
  if((mediaArray1[0]+(zonaNotOpe*_Point)<mediaArray2[0]) && (mediaArray1[2]-(zonaNotOpe*_Point)>mediaArray2[2]) &&
     (spread <= spredMax)){
    buySell = 1;//Fazer venda
    if(rates[1].close<rates[1].open){
      operar = true; 
      if(mediaArray1[0]+(zonaNotOpe*_Point)<mediaArray2[0]){
        operar = true;
      }
      else{
        opeInZone = true;      
      }          
    }
  }  
  
  int statusMedias = -1;
  if(mediaArray1[0]-(zonaNotOpe*_Point)>mediaArray2[0]){
    statusMedias = 0;
  }
  else if(mediaArray1[0]+(zonaNotOpe*_Point)<mediaArray2[0]){
    statusMedias = 1;
  }
  
  posAberta = false;
  listarPositionsOpen(listaPositions);
  
  validarPosicoesAposCruzamento(listaPositions,statusMedias);
  
  if(ArraySize(listaPositions)>0){
    posAberta = true;
  }
  else{
    posAberta = false;
  }   
  
  if(!posAberta){
    beAtivo = false;    
  }
  
  if(posAberta && beTrigger > 0){
    BreakEven(ultimoTick.last);
  }
  
  if(posAberta && trlTrigger > 0){
    TraillingStop(ultimoTick.last);
  }  

  bool abriuNovaOrdem = false; 
  if(PermiteOperar(buySell) && (operar || opeInZone) && !posAberta){
    antesNovaOperacao(listaPositions,buySell);
     
    double buyAskLoss = 0;
    double buyAskProfit = 0;
    double sellAskLoss = 0;
    double sellAskProfit = 0;
    double buyAsk = 0;
    double sellAsk = 0;
    
    PRC = ultimoTick.ask;
    BD = ultimoTick.bid;
    STL = NormalizeDouble(ultimoTick.ask,_Digits);
    TKP = NormalizeDouble(ultimoTick.ask,_Digits);    
    
    if(stopLoss != 0.0){
      buyAskLoss = NormalizeDouble(ultimoTick.ask-(stopLoss*_Point),_Digits);
      sellAskLoss = NormalizeDouble(ultimoTick.bid+(stopLoss*_Point),_Digits);
    }
    if(takeProfit != 0.0){
      buyAskProfit = NormalizeDouble(ultimoTick.ask+(takeProfit*_Point),_Digits);
      sellAskProfit = NormalizeDouble(ultimoTick.bid-(takeProfit*_Point),_Digits);
    }

    buyAsk = PRC;
    sellAsk = BD;
    
    MPositions listaHistorico[];
    datetime horaUltCancles = iTime(_Symbol, _Period, 1) - (_Period*2);
    ListarHistoricoPosicoes(listaHistorico,horaUltCancles);
    
    if(PermitePositionMesmoCandle(listaHistorico)){
      if(buySell == 0){
        if(trade.Buy(lote, _Symbol,0,0,0,"Bot Compra")){
          Print("Ordem de compra padrão sem falha. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
          opeInZone = false;
          abriuNovaOrdem = true;
        }
        else{
          Print("Ordem de compra padrão com falha. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
        }
      }
      else if(buySell == 1){
        if(trade.Sell(lote, _Symbol,0,0,0,"Bot Venda")){
          Print("Ordem de venda padrão sem falha.. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
          opeInZone = false;
          abriuNovaOrdem = true;
        }
        else{
          Print("Ordem de venda padrão com falha.. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
        }    
      }
    }
  }
  
  if(!posAberta && !abriuNovaOrdem && PermiteOperar(buySell)){
    MPositions listHistUlt[];
    datetime horaUltCancles = iTime(_Symbol, _Period, 1) - (_Period*3);    
    ListarHistoricoPosicoes(listHistUlt,horaUltCancles);
    ///Alert("Ultimo candle: ", horaUltCancles," Hist: ", ArraySize(listHistUlt));
    
    if(ArraySize(listHistUlt) > 0){
      //Alert("Tipo_Buy: ",listHistUlt[0].type == POSITION_TYPE_BUY, " OP: ",statusMedias == 1, " Close: ",rates[1].close, " Open: ",rates[1].open);
      if((listHistUlt[0].type == POSITION_TYPE_BUY) && (statusMedias == 0) && (rates[1].close>rates[1].open) &&
         (spread <= spredMax)){
        if(trade.Buy(lote, _Symbol,0,0,0,"Bot Venda rebot")){
          Print("Ordem de venda rebot sem falha.. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
          opeInZone = false;
        }
        else{
          Print("Ordem de venda rebot com falha.. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
        }      
      }
      else if((listHistUlt[0].type == POSITION_TYPE_SELL) && (statusMedias == 1) && (rates[1].close<rates[1].open) &&
              (spread <= spredMax)){
        if(trade.Sell(lote, _Symbol,0,0,0,"Bot Compra rebot")){
          Print("Ordem de compra rebot sem falha.. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
          opeInZone = false;
        }
        else{
          Print("Ordem de venda rebot com falha.. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
        }       
      }
    }    
  }  
}

bool PermiteOperar(int pBuySell){
  //--- Valida dias da semana  
  bool retorna = true;
  int diaDaSemana = DateTimeStructure.day_of_week;  
  bool opValHora = false;
  bool opValToDay = false;
  
  //--- Valida dia da semana  
  if(horasParaOperacao[0].dia==""){
    opValToDay = ArrayContains(diasParaOperacao, diaDaSemana);
  }
  
  
  //--- Valida range de horário  
  MqlDateTime horaInicio, horaFim;
  
  if(horasParaOperacao[0].dia==""){
    for(int i=0;i<=ArraySize(horasParaOperacao)-1;i++){
      TimeToStruct(StringToTime(horasParaOperacao[i].inicio), horaInicio);
      TimeToStruct(StringToTime(horasParaOperacao[i].fim), horaFim);
    
      if (IsTimeWithinRange(horaInicio, horaFim, DateTimeStructure)) {
        opValHora = true;
        break;    
      }
    }
  }
  else{
  //--- Valida dia e range de horario  
    for(int i=0;i<=ArraySize(horasParaOperacao)-1;i++){
      TimeToStruct(StringToTime(horasParaOperacao[i].inicio), horaInicio);
      TimeToStruct(StringToTime(horasParaOperacao[i].fim), horaFim);
    
      if ((diaDaSemana==horasParaOperacao[i].dia) && (IsTimeWithinRange(horaInicio, horaFim, DateTimeStructure))) {
        opValHora = true;
        opValToDay = true;
        break;    
      }
    }  
  }
  
  //--- Compra e Venda
  bool opBuySeel = false;
  if(bHabCompas==bHabVendas){
    opBuySeel = true;
  }
  else if((pBuySell==0) && (bHabCompas)){
    opBuySeel = true;
  }
  else if((pBuySell==1) && (bHabVendas)){
    opBuySeel = true;
  }
  
/*  if(opValToDay){
    Comment("Dia da semana operar: ",diaSemana(diaDaSemana));
  }
  else{
    Comment("Dia da semana NÃO operar: ",diaSemana(diaDaSemana));
  }
  
  if(opValHora){
    Comment("Hora opera: ",DateTimeStructure.hour,':',DateTimeStructure.min,':',DateTimeStructure.sec);
  }
  else{
    Comment("Hora NÃO opera: ",DateTimeStructure.hour,':',DateTimeStructure.min,':',DateTimeStructure.sec);
  } */ 
  
  
  ///Alert("Validação ToDay: ",opValToDay, " Hora: ",opValHora," Operação: ", opBuySeel );
  retorna = (opValToDay && opValHora && opBuySeel);
  return retorna; 
  
}

void TrataDiasHorariosParaOperar(){
  if(opDiasHorarios==""){
    string tmpOpDiasHorarios = opDiasHorarios;
    string tmpDiasHorarios[];
    
    if(tmpOpDiasHorarios.Find(";")>=0){
      StringSplit(tmpOpDiasHorarios,';',tmpDiasHorarios);
    
      for(int i=0;i<ArraySize(tmpDiasHorarios);i++){
        string tmpDiaHorario[];
        StringSplit(tmpDiasHorarios[i],'-',tmpDiaHorario);
      
        MDiasHoras tmp;
        tmp.dia = tmpDiaHorario[0];
        tmp.inicio = tmpDiaHorario[1];
        tmp.fim = tmpDiaHorario[2]; 
      
        ArrayResize(horasParaOperacao, ArraySize(tmpDiasHorarios));
        horasParaOperacao[i] = tmp;           
      }
    }  
  }
}

string diaSemana(int dia){
  string res = "";
  switch(dia)
    {
     case 0 : res = "Domingo"; break;
     case 1 : res = "Segunda"; break;
     case 2 : res = "Terça"; break;
     case 3 : res = "Quarta"; break;
     case 4 : res = "Quinta"; break;
     case 5 : res = "Sexta"; break;
     case 6 : res = "Sábado"; break; 
      
     default: res = dia;
       break;
    }
  return res;
}

   void TrataHorarioParaOperar(){
     string tempHorario = "";
     string tempHoras[];
     
     if((opHorario=="") && (opDiasHorarios=="")){
       tempHorario = "00:00:00-23:59:59";
     }
     else if((opHorario!="") && (opDiasHorarios=="")){
       tempHorario = opHorario;
     }
     
     Print("Horário: ", tempHorario);
     
     if(tempHorario!=""){
       if(tempHorario.Find(";")>=0){   
         StringSplit(tempHorario,';',tempHoras);
         for (int i=0; i< ArraySize(tempHoras) -1;i++){
           string temp[];
           StringSplit(tempHoras[i],'-',temp); 
   
           MDiasHoras mt;
           mt.dia = "";
           mt.inicio = temp[0];
           mt.fim = temp[1];
       
           ArrayResize(horasParaOperacao, ArraySize(tempHoras));
           horasParaOperacao[i] = mt;
         }
       }
       else{
         string temp[];
         StringSplit(tempHorario,'-',temp); 
    
         MDiasHoras mt;
         mt.dia = "";
         mt.inicio = temp[0];
         mt.fim = temp[1];
       
         ArrayResize(horasParaOperacao, 1);
         horasParaOperacao[0] = mt;    
       }
     }
   }

void TrataDiasParaOperar(){
  StringSplit(opDias,';',diasParaOperacao);
  
  if(ArraySize(diasParaOperacao)==0){
    ArrayFree(diasParaOperacao);
    StringSplit("0;1;2;3;4;5;6",';',diasParaOperacao);
  }
}

bool IsTimeWithinRange(const MqlDateTime &inicio, const MqlDateTime &fim, const MqlDateTime &atual) {
    if (atual.hour > inicio.hour && atual.hour < fim.hour) {
        return true;
    } else if (atual.hour == inicio.hour && atual.min >= inicio.min) {
        return true;
    } else if (atual.hour == fim.hour && atual.min <= fim.min) {
        return true;
    }
    return false;
}
 


bool ArrayContains(const string &array[], const int value) {
    for (int i = 0; i <= ArraySize(array)-1; i++) {
        if (array[i] == value) {
            return true; // O valor foi encontrado na matriz
        }
    }
    return false; // O valor não foi encontrado na matriz
}



bool PermitePositionMesmoCandle(MPositions &listaPosHis[]){

  if((operacaoPorCandle > 0) && (ArraySize(listaPosHis) > 0)){
      if(ArraySize(listaPosHis) > operacaoPorCandle){
        return false;
    }
    else{
      return ((tempoAtual - listaPosHis[0].openTime) >= tempoEntreOperacoes);
    }
  }
  else{
    return true;
  }   
}

void ListarHistoricoPosicoes(MPositions &listaPosHis[],datetime dataLimite) {
  ArrayFree(listaPosHis);
  
  datetime dataIniHist = iTime(_Symbol, _Period, 1) - (_Period*2);
  
  HistorySelect(dataIniHist,tempoAtual);
  int totalPosicoes = HistoryDealsTotal(); // Obtém o número total de posições no histórico


  for (int i = totalPosicoes - 1; i >= 0; i--) {
    //if (HistorySelectByPosition(i)) { // Seleciona a posição no histórico
      ulong positionTicket = HistoryDealGetTicket(i);
      if (dataLimite <= HistoryDealGetInteger(positionTicket,DEAL_TIME)) {     
        if(HistoryDealGetString(positionTicket,DEAL_SYMBOL ) == _Symbol && magicNum == HistoryDealGetInteger(positionTicket,DEAL_MAGIC)){
          MPositions newPosition;
          newPosition.position = HistoryDealGetInteger(positionTicket,DEAL_POSITION_ID);
          newPosition.type = HistoryDealGetInteger(positionTicket,DEAL_TYPE);
          newPosition.openTime = HistoryDealGetInteger(positionTicket,DEAL_TIME);
          //newPosition.closeTime = HistoryDealGetInteger(positionTicket,DEAL_TIME_DONE);
      
          int index = ArraySize(listaPosHis);
          ArrayResize(listaPosHis, index+ 1);
          listaPosHis[index] = newPosition;
        }
      }
      else{
        break;
      }
    //}
  }
}

void validarPosicoesAposCruzamento(MPositions &listaPos[],int tipoOperacao) {
  for (int i = ArraySize(listaPos) - 1; i >= 0; i--) {
    ulong positionTicket = listaPos[i].position;
    if (!PositionSelectByTicket(positionTicket)) {
       Print("Falha ao selecionar o ticket");
    } 
    else {
      ENUM_POSITION_TYPE tipoPosicao = PositionGetInteger(POSITION_TYPE);
      if ((tipoOperacao == 0) && (tipoPosicao != POSITION_TYPE_BUY)) {
       // Se a posição não é mais uma posição de compra, feche-a
       Print("Fecha compra em posição de venda - validarPosicoes");
       trade.PositionClose(positionTicket);
       ArrayRemove(listaPos, i);      
      }
      else if ((tipoOperacao == 1) && (tipoPosicao != POSITION_TYPE_SELL)) {
        // Se a posição não é mais uma posição de venda, feche-a
        Print("Fecha venda em posição de compra - validarPosicoes");
        trade.PositionClose(positionTicket);
        ArrayRemove(listaPos, i);                 
      }
    }
  }
}

void AntesNovaOperacao(MPositions &listaPos[], int TipoNovaOp) {
  for (int i = ArraySize(listaPos) - 1; i >= 0; i--) {
    if (!PositionSelectByTicket(listaPos[i].position)) {
      ///Alert("Falha ao selecionar o ticket");
    } else {
      if ((TipoNovaOp == 0) && (PositionGetInteger(POSITION_TYPE) != POSITION_TYPE_BUY)) {
        Print("Fecha compra antes nova operação");
        trade.PositionClose(listaPos[i].position);
        ArrayRemove(listaPos, i); // Remove a posição do array após fechá-la
      } 
      else if ((TipoNovaOp == 1) && (PositionGetInteger(POSITION_TYPE) != POSITION_TYPE_SELL)) {
        Print("Fecha venda antes nova operação");
        trade.PositionClose(listaPos[i].position);
        ArrayRemove(listaPos, i); // Remove a posição do array após fechá-la
      }
    }
  }
}


void listarPositionsOpen(MPositions &listaPos[]){
  ArrayFree(listaPos);
  
  for(int i = PositionsTotal() -1; i>=0; i--){
    ulong positionTicket = PositionGetTicket(i);
    if(!PositionSelectByTicket(positionTicket)){
      Print("Falha ao selecionar o ticket");
    }     
    string symbol = PositionGetString(POSITION_SYMBOL); 
    ulong magic = PositionGetInteger(POSITION_MAGIC);
    
    if((symbol == _Symbol) && (magic == magicNum)){
      MPositions newPosition;
      newPosition.position = positionTicket;
      newPosition.type = PositionGetInteger(POSITION_TYPE);
      
      int index = ArraySize(listaPos);
      ArrayResize(listaPos, index + 1);
      listaPos[index] = newPosition;
    }  
  }
}

bool temPosBuy(){
  bool tpb = false;
  for(int i = ArraySize(listaPositions)-1; i>=0; i--){
    if(listaPositions[i].type == POSITION_TYPE_BUY){
      tpb = true;
      break;
    }    
  }  
  return tpb;
}

bool temPosSell(){
  bool tps = false;
  for(int i = ArraySize(listaPositions)-1; i>=0; i--){
    if(listaPositions[i].type == POSITION_TYPE_SELL){
      tps = true;
      break;
    }    
  }  
  return tps;
}

void FechaPosicao(){
  for(int i = PositionsTotal()-1; i>=0; i--){
    string symbol = PositionGetSymbol(i);
    ulong magic = PositionGetInteger(POSITION_MAGIC);
    
    if(symbol==_Symbol && magic==magicNum){
      ulong positionTicket = PositionGetTicket(POSITION_TICKET);
      ///Alert("Fecha Posição");
      if(trade.PositionClose(positionTicket,desvPts)){
        Print("Posição Fechada - Sem falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
      }
      else{
        Print("Posição Fechada - Com falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());      
      }
    }
  }
}

void DeletaOrdens(){
  for(int i = OrdersTotal()-1; i>=0; i--){
    ulong ticket = OrderGetTicket(i);
    string symbol = OrderGetString(ORDER_SYMBOL);
    ulong magic = OrderGetInteger(ORDER_MAGIC);
    if(symbol == _Symbol && magic == magicNum){
      if(trade.OrderDelete(ticket)){
        Print("Ordem deletada - Sem falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());  
      }
      else{
        Print("Ordem deletada - Com falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
      }
    }  
  }
}

void TraillingStop(double preco){
  double stopLossCorrente = 0;
  double takeProfitCorrente = 0;
  double precoEntrada = 0;
  double trlStop = 0;
    
  for(int i = PositionsTotal()-1; i>=0; i--){
    string symbol = PositionGetSymbol(i);
    ulong magic = PositionGetInteger(POSITION_MAGIC);
    if(symbol==_Symbol){
      ulong positionTicket = PositionGetTicket(i);
      if(!PositionSelectByTicket(positionTicket)){
        Print("Falha ao selecionar o ticket");
      }
     
      precoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
      stopLossCorrente = PositionGetDouble(POSITION_SL);
      takeProfitCorrente = PositionGetDouble(POSITION_TP);
      trlStop = 0;   
      Print("Pegou stopLossCorrente: ",stopLossCorrente," precoEntrada: ",precoEntrada);
      ///Alert("Até aqui antes de alterar entrou sem problemas",preco);
      
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){ 
        ///Print("TraillingStop - Compra",preco," | ",precoEntrada," | ",(trlTrigger*_Point));
        if(preco >= (precoEntrada + (trlTrigger*_Point))){
          Alert("TraillingStop - Atingiu preço trigger: ",(preco - (stopLossCorrente)), " | ",(trlStopLoss+stepTS)*_Point);
          if((trlStopLoss>0) && ((preco - (stopLossCorrente)) > (((trlStopLoss+stepTS)*_Point)) )){
            trlStop = preco-(trlStopLoss*_Point);          
                  
            double novoSL = NormalizeDouble(trlStop,_Digits);

            if(trade.PositionModify(positionTicket,novoSL,takeProfitCorrente)){
              Print("TraillingStop - Sem falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
            }
            else{
              Print("TraillingStop - Com falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
            }
          }          
        } 
      }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
        if(preco < (precoEntrada - (trlTrigger*_Point))){

          Print(" stopLossCorrente: ",(stopLossCorrente),
                " trlStopLoss1: ", (preco+(trlStopLoss*_Point)), 
                " trlStopLoss2: ", (preco-(trlStopLoss*_Point)), 
                " trlStopLoss3: ", ((trlStopLoss*_Point)),
                " Preço: ",preco);
          Print(" precoEntrada: ",(precoEntrada),
                " trlStopLoss1: ", (precoEntrada+(trlStopLoss*_Point)), 
                " trlStopLoss2: ", (precoEntrada-(trlStopLoss*_Point)), 
                " trlStopLoss3: ", ((trlStopLoss*_Point)),
                " Preço: ",preco);  
          Print("trlStopLoss: ", trlStopLoss, " IF1: ",(stopLossCorrente-preco), "IF2: ",((stopLossCorrente-preco) < (trlStopLoss*_Point)));
          if((trlStopLoss>0) && (((stopLossCorrente-preco) > (trlStopLoss*_Point)) || stopLossCorrente==0 )){
            trlStop = preco+(trlStopLoss*_Point); 
            Print("Novo stop: ", trlStop);            
                    
            double novoSL = trlStop;
            ///Alert("Modifica operação - TraillingStop: else");
            if(trade.PositionModify(positionTicket,novoSL,takeProfitCorrente)){
              Print("TraillingStop - Sem falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
            }
            else{
              Print("TraillingStop - Com falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
            }                  
          }
        }       
      }     
    }  
  }
}

void BreakEven(double preco){
  for(int i = PositionsTotal()-1; i>=0; i--){
    string symbol = PositionGetSymbol(i);
    ulong magic = PositionGetInteger(POSITION_MAGIC);
    if(symbol==_Symbol){
      ulong positionTicket = PositionGetTicket(i);
      if(!PositionSelectByTicket(positionTicket)){
        Print("Falha ao selecionar o ticket");
      }
      double precoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
      double takeProfitCorrente = PositionGetDouble(POSITION_TP);
      double beTakeProfit = 0;
      
      
      
      
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
        if(preco >= (precoEntrada + (beTrigger*_Point))){
          if(beStopGain>0){
            beTakeProfit = precoEntrada+(beStopGain*_Point);
          }
          else{
            beTakeProfit = takeProfitCorrente;
          }
          
          if(trade.PositionModify(positionTicket,precoEntrada+(beStopLoss*_Point),beTakeProfit)){
            Print("BreakEven - Sem falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
            beAtivo = true;
          }
          else{
            Print("BreakEven - Com falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
          }
        }
      }
      else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
        if(preco <= (precoEntrada - (beTrigger*_Point))){
          if(beStopGain>0){
            beTakeProfit = precoEntrada-(beStopGain*_Point);
          }
          else{
            beTakeProfit = takeProfitCorrente;
          }        
          
          if(trade.PositionModify(positionTicket,precoEntrada-(beStopLoss*_Point),beTakeProfit)){
            Print("BreakEven - Sem falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
            beAtivo = true;
          }
          else{
            Print("BreakEven - Com falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
          }
        }     
      }
    }
  }
}

bool NovaBarra(){
  static datetime horaAntiga = 0;
  datetime horaAtual = SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE);
  
  if(horaAntiga == 0){
    horaAntiga = horaAtual;
    return false;    
  }
  else if(horaAntiga != horaAtual){
    horaAntiga = horaAtual;
    return true;
  }
  else{
    return false;
  }  
}

/*void OnChartEvent(const int id,         // event ID  
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
  {
   app.ChartEvent(id,lparam,dparam,sparam);
  }*/
