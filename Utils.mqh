/*
  BotTrade.mqh
  CopyRight 2024, Sidjeanp
  https://www.sidjeanp.com
*/
#property library
#property copyright "Sidnei Carlos Sousa Santos"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Arrays\ArrayObj.mqh>
#include <Arrays\List.mqh>
#include <Indicators\Indicator.mqh>
#include <Math\Fuzzy\dictionary.mqh>


struct MBreakEven{
   string pBeLtsTrigger;
   string pBeLtsStopLoss;
   double pBeStopGain;
   int pBeFaixa;
};


struct MPositions{
   ulong                         order;            // Order ticket
   ulong                         position;         // Position ticket
   double                        price;            // Price
   double                        profit;           // Price
   ENUM_POSITION_TYPE            type;             // Order type
   datetime                      openTime;         // Data hora abertura
   datetime                      closeTime;         // Data hora abertura
   bool                          check;
   string                        symbol;
   int                           pFaixa;  
   
   MBreakEven pBreakEven;
 };
 
struct MDiasHoras{
  string dia;
  string inicio;
  string fim;
};



struct MParam{
   string pSymbol;
   ENUM_TIMEFRAMES pPeriod;
   double pPriceOpen;
   double pLote;
   double pStopLoss;
   double pTakeProfit;
   double pZonaNotOpe;
   ulong pMagicNum;
   ulong pDesvPts;
   double pSpredMax;
   int pOperacaoPorCandle;
   string pLtsCrossMediaMovel;
   
   MBreakEven pBreakEven;
  
 };

enum ENUM_TO_OPERATION_TYPE {
    UNDEF = -1,
    TO_BUY = 0,
    TO_SELL = 1
};


void TrataDiasParaOperar(string pOpDias,string &pDiasParaOperacao[]) export{
  StringSplit(pOpDias,';',pDiasParaOperacao);
  
  if(ArraySize(pDiasParaOperacao)==0){
    ArrayFree(pDiasParaOperacao);
    StringSplit("0;1;2;3;4;5;6",';',pDiasParaOperacao);
  }
} 



void TrataHorarioParaOperar(string pOpHorario, string pOpDiasHorarios, MDiasHoras &pHorasParaOperacao[]) {
    string tempHorario = "";
    string tempHoras[];
  
    if ((StringLen(pOpHorario) > 0) && (StringLen(pOpDiasHorarios) == 0)) {
        tempHorario = pOpHorario;
    }  
    else if (StringLen(pOpDiasHorarios) > 0) {
        tempHorario = pOpDiasHorarios;
    }  
    else {
        tempHorario = "00:00:00-23:59:59";
    }
  
    Print("Horário Operação: ", "'", bool(tempHorario == ""), "'");
  
    Print("pOpHorario: ", "'", bool(StringLen(pOpHorario) == 0), "'");
    Print("pOpDiasHorarios: ", "'", bool(StringLen(pOpDiasHorarios) == 0), "'");
  
    if (tempHorario != "") {
        if (StringFind(tempHorario, ";") >= 0) {   
            StringSplit(tempHorario, ';', tempHoras);
            for (int i = 0; i < ArraySize(tempHoras) - 1; i++) {
                string temp[];
                StringSplit(tempHoras[i], '-', temp); 

                MDiasHoras mt;
                mt.dia = "";
                mt.inicio = temp[0];
                mt.fim = temp[1];
    
                ArrayResize(pHorasParaOperacao, ArraySize(tempHoras));
                pHorasParaOperacao[i] = mt;
            }
        }
        else {
            string temp[];
            StringSplit(tempHorario, '-', temp); 
 
            MDiasHoras mt;
            mt.dia = "";
            mt.inicio = temp[0];
            mt.fim = temp[1];
    
            ArrayResize(pHorasParaOperacao, 1);
            pHorasParaOperacao[0] = mt;    
        }
    }
}


void TrataDiasHorariosParaOperar(string pOpDiasHorarios, MDiasHoras &pHorasParaOperacao[] ){
  if(StringLen(pOpDiasHorarios)>0){
    string tmpOpDiasHorarios = pOpDiasHorarios;
    string tmpDiasHorarios[];
    
    if(tmpOpDiasHorarios.Find(";")>=0){
      StringSplit(tmpOpDiasHorarios,';',tmpDiasHorarios);
      ArrayFree(pHorasParaOperacao);
      
      for(int i=0;i<ArraySize(tmpDiasHorarios);i++){
        string tmpDiaHorario[];
        StringSplit(tmpDiasHorarios[i],'-',tmpDiaHorario);
      
        MDiasHoras tmp;
        tmp.dia = tmpDiaHorario[0];
        tmp.inicio = tmpDiaHorario[1];
        tmp.fim = tmpDiaHorario[2]; 
      
        ArrayResize(pHorasParaOperacao, ArraySize(pHorasParaOperacao)+1);
        pHorasParaOperacao[i] = tmp;           
      }
    }  
  }
}

void CheckStatusMedias(ENUM_TO_OPERATION_TYPE &pStatusMedias, double &mediaRapida[], double &mediaLenta[], double pZonaNotOpe){
  pStatusMedias = UNDEF;
  if(mediaRapida[0]-(pZonaNotOpe*_Point)>mediaLenta[0]){
    pStatusMedias = TO_BUY;
  }
  else if(mediaRapida[0]+(pZonaNotOpe*_Point)<mediaLenta[0]){
    pStatusMedias = TO_SELL;
  }   
} 


void ListarHistoricoPosicoes(MPositions &listaPosHis[], datetime dataLimite, string pSymbol, ENUM_TIMEFRAMES pPeriod, ulong pMagicNum, datetime pTempoAtual) {
    ArrayResize(listaPosHis, 0); // Limpa o vetor

    datetime dataIniHist = iTime(pSymbol, pPeriod, 0);
  
    HistorySelect(dataIniHist, pTempoAtual);
    int totalPosicoes = HistoryDealsTotal(); // Obtém o número total de posições no histórico

    for (int i = totalPosicoes - 1; i >= 0; i--) {
        ulong positionTicket = HistoryDealGetTicket(i);
        datetime dataTicket = HistoryDealGetInteger(positionTicket, DEAL_TIME);
        
        if (dataTicket >= dataLimite) {     
            if (HistoryDealGetString(i, DEAL_SYMBOL) == pSymbol && pMagicNum == HistoryDealGetInteger(i, DEAL_MAGIC)) {
                MPositions newPosition;
                newPosition.position = HistoryDealGetInteger(i, DEAL_POSITION_ID);
                newPosition.type = (ENUM_POSITION_TYPE)HistoryDealGetInteger(i, DEAL_TYPE);
                newPosition.openTime = datetime(HistoryDealGetInteger(i, DEAL_TIME));

                int index = ArraySize(listaPosHis);
                ArrayResize(listaPosHis, index + 1);
                listaPosHis[index] = newPosition;
            }
        } else {
            break;
        }
    }
}



bool PermitePositionMesmoCandle(MPositions &listaPosHis[], datetime pTempoAtual, int pOperacaoPorCandle, int pTempoEntreOperacoes){
  int qtdHistori = ArraySize(listaPosHis); 

  if((pOperacaoPorCandle > 0) && (ArraySize(listaPosHis) > 0)){
      if(ArraySize(listaPosHis) > pOperacaoPorCandle){
        return false;
    }
    else{
      return ((pTempoAtual - listaPosHis[0].openTime) >= pTempoEntreOperacoes);
    }
  }
  else{
    return true;
  }   
}

bool ArrayContains(const string &array[], const int value) {
    for (int i = 0; i <= ArraySize(array)-1; i++) {
        if (array[i] == IntegerToString(value)) {
            return true; // O valor foi encontrado na matriz
        }
    }
    return false; // O valor não foi encontrado na matriz
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

bool ValidaOrders(MPositions &listaOrders[]){
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

bool TemOrder(MPositions &listaOrders[],ENUM_TO_OPERATION_TYPE pStatusMedia,string pSymbol,ulong pMagicNum){
  bool vReturn = false;
  for(int i = 0; i < ArraySize(listaOrders);i++){
    if((listaOrders[i].type == (ENUM_POSITION_TYPE)pStatusMedia) && (listaOrders[i].symbol == pSymbol)){
        vReturn = true;
    }
  }
  return vReturn;
}

bool TemPosition(MPositions &listaPos[],ENUM_TO_OPERATION_TYPE pStatusMedia,string pSymbol,ulong pMagicNum){
  bool vReturn = false;
  for(int i = 0; i < ArraySize(listaPos);i++){
    if(listaPos[i].type == (ENUM_POSITION_TYPE)pStatusMedia){
 
      vReturn = true;          
    }
  }
  return vReturn;
}

ENUM_TO_OPERATION_TYPE MediaReversa(ENUM_TO_OPERATION_TYPE pStatusMedia){
  if(TO_BUY == pStatusMedia){
    return TO_SELL;
  }
  else{
    return TO_BUY;
  }  
}

void CarregarOrdens(MPositions &posicoes[]) {
    int totalOrdens = HistoryOrdersTotal(); // Obtém o número total de ordens no histórico

    // Limpa o vetor
    ArrayResize(posicoes, 0);

    for (int i = totalOrdens - 1; i >= 0; i--) {
        ulong orderTicket = HistoryOrderGetTicket(i);
        MPositions novaPosicao;
        novaPosicao.order = orderTicket;
        novaPosicao.position = HistoryOrderGetInteger(orderTicket, ORDER_POSITION_ID);
        novaPosicao.price = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_OPEN);
        novaPosicao.type = (ENUM_POSITION_TYPE)HistoryOrderGetInteger(orderTicket, ORDER_TYPE);
        novaPosicao.openTime = datetime(HistoryOrderGetInteger(orderTicket, ORDER_TIME_SETUP));
        novaPosicao.closeTime = datetime(HistoryOrderGetInteger(orderTicket, ORDER_TIME_DONE));
        //novaPosicao.check = HistoryOrderGetBoolean(orderTicket, ORDER_TIME_DONE);
        novaPosicao.symbol = HistoryOrderGetString(orderTicket, ORDER_SYMBOL);

        // Adiciona a nova posição ao vetor
        int index = ArraySize(posicoes);
        ArrayResize(posicoes, index + 1);
        posicoes[index] = novaPosicao;
    }
}

void listaPositionsPadrao(MPositions &listPosit[], string pSymbol,ulong pMagic){
  setCheckFalse(listPosit);
  
  for(int i = PositionsTotal() -1; i>=0; i--){
    ulong positionTicket = PositionGetTicket(i);
    if(!PositionSelectByTicket(positionTicket)){
      Print("Falha ao selecionar o ticket");
    }
    else{     
      string vSymbol = PositionGetString(POSITION_SYMBOL); 
      ulong vMagic = PositionGetInteger(POSITION_MAGIC);
    
      if((pSymbol == vSymbol) && ((pMagic == vMagic) || (pMagic == 0))){
        int pos = buscaListaPosition(listPosit,positionTicket);
        if (pos < 0){
          MPositions newPosition;
          newPosition.position = positionTicket;
          newPosition.type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
          newPosition.symbol = pSymbol;
          newPosition.profit = PositionGetDouble(POSITION_PROFIT);
          newPosition.price = PositionGetDouble(POSITION_PRICE_OPEN);
          newPosition.check = true;
          newPosition.pFaixa = 0;
      
          int index = ArraySize(listPosit);
          ArrayResize(listPosit, index + 1);
          listPosit[index] = newPosition;
        }
        else{
          listPosit[pos].profit = PositionGetDouble(POSITION_PROFIT);
          listPosit[pos].check = true;
        }
      } 
    } 
  }
  
  if(temCheckFalse(listPosit) > 0){
    removePosition(listPosit);
  }
  
} 

int buscaListaPosition(MPositions &listPosit[],ulong pPosition){
  int index = -1;
  for(int i = 0; i < ArraySize(listPosit); i++){
    if(listPosit[i].position == pPosition){
      index = i;
      break;
    }
  }
  
  return index;
}

void setCheckFalse(MPositions &listPosit[]){
  for(int i = 0; i < ArraySize(listPosit); i++){
    listPosit[i].check = false;
  }
}

int temCheckFalse(MPositions &listPosit[]){
  int qtd = 0;
  for(int i = 0; i < ArraySize(listPosit); i++){
    if(!listPosit[i].check){
      qtd++;
    }
  }
  
  return qtd;
}

void removePosition(MPositions &listPosit[]) {
  int tamanhoFiltrado = 0; // Rastreia o número de posições a manter

  // Itera pela lista original e filtra as posições a manter
  for (int i = 0; i < ArraySize(listPosit); i++) {
    if (listPosit[i].check) { // Verifica a condição de remoção
      // Se a posição atende ao critério (por exemplo, listPosit[i].check é verdadeiro),
      // copie-a para o array original no índice filtrado
      listPosit[tamanhoFiltrado] = listPosit[i];
      tamanhoFiltrado++; // Incrementa o contador de tamanho filtrado
    }
  }

  // Redimensione o array original para coincidir com o tamanho filtrado
  ArrayResize(listPosit, tamanhoFiltrado);
}

void listaOrdersPadrao(MPositions &listOrders[], string pSymbol,ulong pMagic){
 // Obtém o número total de posições
 int totalPositions = PositionsTotal();
 
 ArrayFree(listOrders);
 
 // Percorre todas as posições
  for (int i = 0; i < totalPositions; ++i) {
     // Seleciona a posição atual
     if (OrderSelect(i)) {
       MPositions newPosition;
       newPosition.symbol = OrderGetString(ORDER_SYMBOL);
       newPosition.order = OrderGetInteger(ORDER_POSITION_ID);
       //newPosition.type = OrderGetInteger (EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE))));

      
       int index = ArraySize(listOrders);
       ArrayResize(listOrders, index + 1);
       listOrders[index] = newPosition;
     }          
  }
}

ENUM_MA_METHOD StrToMA_METHOD(string strMA_METHOD) {
  if (strMA_METHOD == "MODE_SMA") return MODE_SMA;
  else if (strMA_METHOD == "MODE_EMA") return MODE_EMA;
  else if (strMA_METHOD == "MODE_SMMA") return MODE_SMMA;
  else if (strMA_METHOD == "MODE_LWMA") return MODE_LWMA;
  else {
    return MODE_SMA; // Ou outro valor padrão
  }
}



ENUM_APPLIED_PRICE StrToAPPLIED_PRICE(string strAPPLIED_PRICE) {
  // Definimos um array associativo para mapear nomes de strings para valores ENUM_APPLIED_PRICE

   if( strAPPLIED_PRICE == "PRICE_CLOSE") return PRICE_CLOSE;
   else if( strAPPLIED_PRICE == "PRICE_OPEN") return PRICE_OPEN;
   else if( strAPPLIED_PRICE == "PRICE_HIGH") return PRICE_HIGH;
   else if( strAPPLIED_PRICE == "PRICE_LOW") return PRICE_LOW;
   else {
     return PRICE_CLOSE;
   }
}


color StrToColor(string strColor) {
  // Definimos um array associativo para mapear nomes de strings para valores ENUM_APPLIED_PRICE

   if (strColor == "clrBlack") return clrBlack;
   else if (strColor == "clrDarkGreen") return clrDarkGreen;
   else if (strColor == "clrDarkSlateGray") return clrDarkSlateGray;
   else if (strColor == "clrOlive") return clrOlive;
   else if (strColor == "clrGreen") return clrGreen;
   else if (strColor == "clrTeal") return clrTeal;
   else if (strColor == "clrNavy") return clrNavy;
   else if (strColor == "clrPurple") return clrPurple;
   else if (strColor == "clrMaroon") return clrMaroon;
   else if (strColor == "clrIndigo") return clrIndigo;
   else if (strColor == "clrMidnightBlue") return clrMidnightBlue;
   else if (strColor == "clrDarkBlue") return clrDarkBlue;
   else if (strColor == "clrDarkOliveGreen") return clrDarkOliveGreen;
   else if (strColor == "clrSaddleBrown") return clrSaddleBrown;
   else if (strColor == "clrForestGreen") return clrForestGreen;
   else if (strColor == "clrOliveDrab") return clrOliveDrab;
   else if (strColor == "clrSeaGreen") return clrSeaGreen;
   else if (strColor == "clrDarkGoldenrod") return clrDarkGoldenrod;
   else if (strColor == "clrDarkSlateBlue") return clrDarkSlateBlue;
   else if (strColor == "clrSienna") return clrSienna;
   else if (strColor == "clrMediumBlue") return clrMediumBlue;
   else if (strColor == "clrBrown") return clrBrown;
   else if (strColor == "clrDarkTurquoise") return clrDarkTurquoise;
   else if (strColor == "clrDimGray") return clrDimGray;
   else if (strColor == "clrLightSeaGreen") return clrLightSeaGreen;
   else if (strColor == "clrDarkViolet") return clrDarkViolet;
   else if (strColor == "clrFireBrick") return clrFireBrick;
   else if (strColor == "clrMediumVioletRed") return clrMediumVioletRed;
   else if (strColor == "clrMediumSeaGreen") return clrMediumSeaGreen;
   else if (strColor == "clrChocolate") return clrChocolate;
   else if (strColor == "clrCrimson") return clrCrimson;
   else if (strColor == "clrSteelBlue") return clrSteelBlue;
   else if (strColor == "clrGoldenrod") return clrGoldenrod;
   else if (strColor == "clrMediumSpringGreen") return clrMediumSpringGreen;
   else if (strColor == "clrLawnGreen") return clrLawnGreen;
   else if (strColor == "clrCadetBlue") return clrCadetBlue;
   else if (strColor == "clrDarkOrchid") return clrDarkOrchid;
   else if (strColor == "clrYellowGreen") return clrYellowGreen;
   else if (strColor == "clrLimeGreen") return clrLimeGreen;
   else if (strColor == "clrOrangeRed") return clrOrangeRed;
   else if (strColor == "clrDarkOrange") return clrDarkOrange;
   else if (strColor == "clrOrange") return clrOrange;
   else if (strColor == "clrGold") return clrGold;
   else if (strColor == "clrYellow") return clrYellow;
   else if (strColor == "clrChartreuse") return clrChartreuse;
   else if (strColor == "clrLime") return clrLime;
   else if (strColor == "clrSpringGreen") return clrSpringGreen;
   else if (strColor == "clrAqua") return clrAqua;
   else if (strColor == "clrDeepSkyBlue") return clrDeepSkyBlue;
   else if (strColor == "clrBlue") return clrBlue;
   else if (strColor == "clrMagenta") return clrMagenta;
   else if (strColor == "clrRed") return clrRed;
   else if (strColor == "clrGray") return clrGray;
   else if (strColor == "clrSlateGray") return clrSlateGray;
   else if (strColor == "clrPeru") return clrPeru;
   else if (strColor == "clrBlueViolet") return clrBlueViolet;
   else if (strColor == "clrLightSlateGray") return clrLightSlateGray;
   else if (strColor == "clrDeepPink") return clrDeepPink;
   else if (strColor == "clrMediumTurquoise") return clrMediumTurquoise;
   else if (strColor == "clrDodgerBlue") return clrDodgerBlue;
   else if (strColor == "clrTurquoise") return clrTurquoise;
   else if (strColor == "clrRoyalBlue") return clrRoyalBlue;
   else if (strColor == "clrSlateBlue") return clrSlateBlue;
   else if (strColor == "clrDarkKhaki") return clrDarkKhaki;
   else if (strColor == "clrIndianRed") return clrIndianRed;
   else if (strColor == "clrMediumOrchid") return clrMediumOrchid;
   else if (strColor == "clrGreenYellow") return clrGreenYellow;
   else if (strColor == "clrMediumAquamarine") return clrMediumAquamarine;
   else if (strColor == "clrDarkSeaGreen") return clrDarkSeaGreen;
   else if (strColor == "clrTomato") return clrTomato;
   else if (strColor == "clrRosyBrown") return clrRosyBrown;
   else if (strColor == "clrOrchid") return clrOrchid;
   else if (strColor == "clrMediumPurple") return clrMediumPurple;
   else if (strColor == "clrPaleVioletRed") return clrPaleVioletRed;
   else if (strColor == "clrCoral") return clrCoral;
   else if (strColor == "clrCornflowerBlue") return clrCornflowerBlue;
   else if (strColor == "clrDarkGray") return clrDarkGray;
   else if (strColor == "clrSandyBrown") return clrSandyBrown;
   else if (strColor == "clrMediumSlateBlue") return clrMediumSlateBlue;
   else if (strColor == "clrTan") return clrTan;
   else if (strColor == "clrDarkSalmon") return clrDarkSalmon;
   else if (strColor == "clrBurlyWood") return clrBurlyWood;
   else if (strColor == "clrHotPink") return clrHotPink;
   else if (strColor == "clrSalmon") return clrSalmon;
   else if (strColor == "clrViolet") return clrViolet;
   else if (strColor == "clrLightCoral") return clrLightCoral;
   else if (strColor == "clrSkyBlue") return clrSkyBlue;
   else if (strColor == "clrLightSalmon") return clrLightSalmon;
   else if (strColor == "clrPlum") return clrPlum;
   else if (strColor == "clrKhaki") return clrKhaki;
   else if (strColor == "clrLightGreen") return clrLightGreen;
   else if (strColor == "clrAquamarine") return clrAquamarine;
   else if (strColor == "clrSilver") return clrSilver;
   else if (strColor == "clrLightSkyBlue") return clrLightSkyBlue;
   else if (strColor == "clrLightSteelBlue") return clrLightSteelBlue;
   else if (strColor == "clrLightBlue") return clrLightBlue;
   else if (strColor == "clrPaleGreen") return clrPaleGreen;
   else if (strColor == "clrThistle") return clrThistle;
   else if (strColor == "clrPowderBlue") return clrPowderBlue;
   else if (strColor == "clrPaleGoldenrod") return clrPaleGoldenrod;
   else if (strColor == "clrPaleTurquoise") return clrPaleTurquoise;
   else if (strColor == "clrLightGray") return clrLightGray;
   else if (strColor == "clrWheat") return clrWheat;
   else if (strColor == "clrNavajoWhite") return clrNavajoWhite;
   else if (strColor == "clrMoccasin") return clrMoccasin;
   else if (strColor == "clrLightPink") return clrLightPink;
   else if (strColor == "clrGainsboro") return clrGainsboro;
   else if (strColor == "clrPeachPuff") return clrPeachPuff;
   else if (strColor == "clrPink") return clrPink;
   else if (strColor == "clrBisque") return clrBisque;
   else if (strColor == "clrLightGoldenrod") return clrLightGoldenrod;
   else if (strColor == "clrBlanchedAlmond") return clrBlanchedAlmond;
   else if (strColor == "clrLemonChiffon") return clrLemonChiffon;
   else if (strColor == "clrBeige") return clrBeige;
   else if (strColor == "clrAntiqueWhite") return clrAntiqueWhite;
   else if (strColor == "clrPapayaWhip") return clrPapayaWhip;
   else if (strColor == "clrCornsilk") return clrCornsilk;
   else if (strColor == "clrLightYellow") return clrLightYellow;
   else if (strColor == "clrLightCyan") return clrLightCyan;
   else if (strColor == "clrLinen") return clrLinen;
   else if (strColor == "clrLavender") return clrLavender;
   else if (strColor == "clrMistyRose") return clrMistyRose;
   else if (strColor == "clrOldLace") return clrOldLace;
   else if (strColor == "clrWhiteSmoke") return clrWhiteSmoke;
   else if (strColor == "clrSeashell") return clrSeashell;
   else if (strColor == "clrIvory") return clrIvory;
   else if (strColor == "clrHoneydew") return clrHoneydew;
   else if (strColor == "clrAliceBlue") return clrAliceBlue;
   else if (strColor == "clrLavenderBlush") return clrLavenderBlush;
   else if (strColor == "clrMintCream") return clrMintCream;
   else if (strColor == "clrSnow") return clrSnow;
   else if (strColor == "clrWhite") return clrWhite;
   else {
     return clrWhite;
   }

}