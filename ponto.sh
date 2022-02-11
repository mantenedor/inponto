#!/bin/bash

#GLOBALS
FILE="/var/www/html/ponto/api/ponto.json"
FFERIADOS="/var/www/html/ponto/api/feriados"
VIRADA=0
CARGA=28800

if [ ! -f $FILE ];then
	echo '{} '> $FILE
fi

function PONTEIRO {

	ALVO=$TIMESTAMP
	HOJE=$(date +%s -d"`date '+%b %d, %Y'`")
	ONTEM=$(($ALVO - 1))

	DATA=`date -d@$ALVO '+%Y-%m-%d'`
        HORA=`date -d@$ALVO '+%H:%M:%S'`
        ANO=`date -d@$ALVO '+%Y'`
        MES=`date -d@$ALVO '+%m'`

}

function CONVERTE {

	MIN=`echo "$SEC/60" | bc -l`
        HOR=`echo "$MIN/60" | bc -l`
        HORAS=${HOR%.*}
        MINUTOS="0$(echo "$HOR-$HORAS" | bc)"
        SEGUNDOS="0.$(echo "$MIN" | cut -d. -f2)"
        MINUTOS=$(echo "$MINUTOS*60" | bc)
        SEGUNDOS=$(echo "$SEGUNDOS*60" | bc)
        MINUTOS=${MINUTOS%.*}
        SEGUNDOS=${SEGUNDOS%.*}
        CONVERTIDO="$HORAS:$MINUTOS:$SEGUNDOS"

}

function FIMDESEMANA {

	if [ $DIA -eq 0 -o $DIA -eq 6 ];then
		echo "É fim de semana"
		FDS=$DENTRO
	fi

}

function FERIADO {

	for i in `cat $FFERIADOS | cut -d: -f1`;do
		if [ $i == "$DATA" ];then
        	        echo "É feriado"
			FERIADO=$DENTRO
        	fi
	done
}

function PLANTAO {
	
	if [ $SENTIDO = "saida" -a $ENTRADAS -eq 0 -a $VIRADA -eq 0 ];then
		
		ULTIMADATA=`echo $OBJ | jq -r '.meta.ultimo_registro'`
		ULTIMADATA=`date -d@$ULTIMADATA '+%Y-%m-%d'`
	
		echo "$OBJ" | jq .

		echo ""	
		echo -e "Você tem um exediente em aberto em: $ULTIMADATA"
		echo "Trata-se de uma virada? (s/n)"
		read VIRADA

		if [ $VIRADA == "s" ];then
			
			echo 'Informe a data da saida "YYYY-MM-DD": '
			read DATA
			echo 'Informe a hora da saida "HH:MM:SS": '
			read HORA
			echo 'Comente a virada: '
			read COMENTARIO

			LOCAL=`pwd`
			DATA=$DATA

			"$LOCAL"/ponto.sh -i virada $ULTIMADATA 23:59:59 1 
			"$LOCAL"/ponto.sh -i virada $DATA 00:00:00 1
			"$LOCAL"/ponto.sh -i "$COMENTARIO" $DATA $HORA 1 
			
			#TIMESTAMP=$(($(date +%s -d"$ULTIMADATA") + 86399))
			#REGISTRO

			exit

		else
			if [ $VIRADA == "n" ];then 
				echo ""
				echo "Informe a hora da saída para a data $ULTIMADATA:"
				read HORA
				
				LOCAL=`pwd`
				"$LOCAL"/ponto.sh -i "correção" $ULTIMADATA $HORA  
				exit
			else
				PLANTAO
			fi
		fi

	fi

}

function CONTAFIMDESEMANA {
count=0	
while [[ $count -lt $DIAS ]]; do  
	count=$(($count +1))
	SOD="$ANO-$MES-$count"
	SOD=`date +%w -d"$SOD"`
       	if [ $SOD -eq 0 -o $SOD -eq 6  ];then
		FDR=$(($FDR + 1))
	fi	
done

}


function DATAMES {

	FSR=0
        MES=$(date -d"$DATA" +%m)
        FERIADOS=$(cat $FFERIADOS | cut -d: -f1 | grep "\-$MES\-" | wc -l)
        ANO=$(date -d"$DATA" +%Y)
        INICIO=$(date +%s -d "$ANO-$MES-01")
        MES=$(( "10#$MES" + 1 ))
        if [ $MES -eq 13  ];then
                MES=01
                ANO=$(($ANO + 1))
        fi
        FIM=$((`date +%s -d $ANO-$MES-01` -1))
        SEC=$(( $FIM - $INICIO ))
        MIN=`echo "$SEC/60" | bc -l`
        HOR=`echo "$MIN/60" | bc -l`
        ANO=$(date -d"$DATA" +%Y)
        MES=$(date -d"$DATA" +%m)
        DIAS=$(date -d@"$FIM" +%d)
	
	#CONTAFIMDESEMANA
        
	UTIL=0
        FERIADOUTIL=0
        count=1

        while [ $count -le $DIAS ];do
        
		if [ `date +%w -d"$ANO-$MES-$count"` -ne 0 -a `date +%w -d"$ANO-$MES-$count"` -ne 6 ];then
                        UTIL=$(( $UTIL + 1  ))
                fi
                count=$(( $count + 1 ))
        
	done

        for i in `cat $FFERIADOS | cut -d: -f1 | grep "\-$MES\-"`; do

                if [ `date +%w -d"$i"` -ne 0 -a `date +%w -d"$i"` -ne 6 ];then
                        FERIADOUTIL=$(( $FERIADOUTIL + 1  ))
                        #echo $i
                fi

        done
	
}

function ANUAL {

	saldos=(`echo $OBJ | jq -r '.["'$ANO'"][].sumario.jornada'`)
	SDA=0
	for i in $(echo ${saldos[@]});do
		SDA=$(($SDA + $i))
	done
	
	viradas=(`echo $OBJ | jq -r '.["'$ANO'"][].sumario.viradas'`)
	VIA=0
	for i in $(echo ${viradas[@]});do
		VIA=$(($VIA + $i))
	done
	
	extras=(`echo $OBJ | jq -r '.["'$ANO'"][].sumario.extra'`)
	EXTA=0
	for i in $(echo ${extras[@]});do
		EXTA=$(($EXTA + $i))
	done
	
	noturnas=(`echo $OBJ | jq -r '.["'$ANO'"][].sumario.noturno'`)
	NOA=0
	for i in $(echo ${noturnas[@]});do
		NOA=$(($NOA + $i))
	done
	
	feriados=(`echo $OBJ | jq -r '.["'$ANO'"][].sumario.saldo_feriados'`)
	FEA=0
	for i in $(echo ${feriados[@]});do
		FEA=$(($FEA + $i))
	done
	
	fimdesemanas=(`echo $OBJ | jq -r '.["'$ANO'"][].sumario.fim_de_semana'`)
	FSA=0
	for i in $(echo ${fimdesemanas[@]});do
		FSA=$(($FSA + $i))
	done

}


function MENSAL {

	DATAMES
		
	saldos=(`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"][].sumario.jornada'`)
	SD=0
	for i in $(echo ${saldos[@]});do
		SD=$(($SD + $i))
	done
	
	viradas=(`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"][].sumario.virada'`)
	VI=0
	for i in $(echo ${viradas[@]});do
		VI=$(($VI + $i))
	done
	
	extras=(`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"][].sumario.extra'`)
	EXT=0
	for i in $(echo ${extras[@]});do
		EXT=$(($EXT + $i))
	done
	
	noturnas=(`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"][].sumario.noturno'`)
	NO=0
	for i in $(echo ${noturnas[@]});do
		NO=$(($NO + $i))
	done
	
	feriados=(`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"][].sumario.saldo_feriados'`)
	FE=0
	for i in $(echo ${feriados[@]});do
		FE=$(($FE + $i))
	done
	
	fimdesemanas=(`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"][].sumario.fim_de_semana'`)
	FS=0
	for i in $(echo ${fimdesemanas[@]});do
		FS=$(($FS + $i))
	done
	DIASTRABALHADOS=(`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"][].sumario.jornada' | grep -v "null" | wc -l`)
	CARGAMENSAL=$(( $(( $UTIL - $FERIADOUTIL )) * $CARGA ))
	SALDOMENSAL=$(( $SD - $(( $CARGAMENSAL - $(( $DIASTRABALHADOS * $CARGA)) )) ))
	#SALDOMENSAL=$SD 
	
	VI=$(( $VI / 2 ))
	echo "jornada: $SD"
	echo "viradas: $VI"
	echo "externas: $EXT"
	echo "noturnas: $NO"
	echo "feriados: $FE"
	echo "fim de semana: $FS"

}

function EXTRA {
	
	DIA=`date +%w -d"$DATA"`

	if [ $DIA -eq 0 -o $DIA -eq 6 ];then
		EX=$DENTRO
	else
		if [ $DENTRO -gt $CARGA ];then
			EX=$(($DENTRO - $CARGA))
		else
			EX=0
		fi		
	fi
	
	EXTRAS=`date -d@$(($(date +%s -d"$DATA") + $EX)) '+%H:%M:%S'`
}

function NOTURNA {

	REGISTROS=`echo $OBJ | jq '.["'$ANO'"]["'$MES'"]["'$DATA'"].registros[] | .timestamp' | tr -d '"' | sort -n`
        N=`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"]["'$DATA'"].sumario.noturno'`
	
	count=0
	noturnas=()
	
	HORANOTURNA=(05:00:00 22:00:00)
	FICTAOUT=`date +%s -d"$DATA ${HORANOTURNA[0]}"`
	FICTAIN=`date +%s -d"$DATA ${HORANOTURNA[1]}"`
	INDEX=$(($ENTRADAS - 2))

        if [ $N == null ];then
                N=0
        fi

	for i in $(echo $REGISTROS);do

		noturnas[$count]="$i"
                count=$((count + 1))
        	
	done
	
	arr=(${noturnas[@]:$INDEX:2})
		
	PENULTIMA=${arr[0]}
	ULTIMA=${arr[1]}
	
	if [ -z $ULTIMA ];then
               	ULTIMA=0
		PENULTIMA=0
        fi

	if [ $ULTIMA -ge $FICTAIN -a $PENULTIMA -ge $FICTAIN ];then
		DIFF=$(($ULTIMA - $PENULTIMA))
        	if [ $SENTIDO == "saida" ];then
			N=$(($N + $DIFF))
		fi
	else
		if [ $ULTIMA -ge $FICTAIN ];then
			DIFF=$(($ULTIMA - $FICTAIN))
			if [ $SENTIDO == "saida"  ];then
				N=$(($N + $DIFF))
			fi
		fi
	fi
	
	if [ $ULTIMA -le $FICTAOUT -a $PENULTIMA -le $FICTAOUT ];then
		DIFF=$(($ULTIMA - $PENULTIMA))
        	if [ $SENTIDO == "saida" ];then
			N=$(($N + $DIFF))
		fi
	else
		if [ $PENULTIMA -le $FICTAOUT ];then
			DIFF=$(($FICTAOUT - $PENULTIMA))
			if [ $SENTIDO == "saida"  ];then
				N=$(($N + $DIFF))
			fi
		fi
	fi

	NOTURNO=`date -d@$(($(date +%s -d"$DATA") + $N)) '+%H:%M:%S'`

}

function SUMARIO {
	

	REGISTROS=`echo $OBJ | jq '.["'$ANO'"]["'$MES'"]["'$DATA'"].registros[] | .timestamp' | tr -d '"' | sort -n`	
        DENTRO=`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"]["'$DATA'"].sumario.em_expediente'`
        FORA=`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"]["'$DATA'"].sumario.fora_expediente'`

        if [ $DENTRO == null ];then
                DENTRO=0
        fi

        if [ $FORA == null ];then
                FORA=0
        fi

	count=0
        array=()

	RANGE=$(($ENTRADAS - 2))

	for i in $(echo $REGISTROS);do
        
		array[$count]="$i"
                count=$((count + 1))
                arr=(${array[@]:$RANGE:2})
	
	done

	PENULTIMO=${arr[0]}
        ULTIMO=${arr[1]}
        
	if [ -z $ULTIMO ];then
                ULTIMO=0
                PENULTIMO=0
		ULTIMOREGISTRO=`echo $REGISTROS | tail -n 1`
	else
		ULTIMOREGISTRO=$ULTIMO
        fi
	

	#DIFF=$((array[0] - $(date +%s -d"$DATA")))
	
	DIFF=$(($ULTIMO - $PENULTIMO))

        if [ $SENTIDO == "saida"  ];then
                DENTRO=$(($DENTRO + $DIFF))
        fi

        if [ $SENTIDO == "entrada"  ];then
                FORA=$(($FORA + $DIFF))
        fi

	TRABALHADAS=`date -d@$(($(date +%s -d"$DATA") + $DENTRO)) '+%H:%M:%S'`
	SALDO=$(($DENTRO - $CARGA))
	INTERVALO=`date -d@$(($(date +%s -d"$DATA") + $FORA)) '+%H:%M:%S'`

	DESCANCO=0
	TEMPO=$TIMESTEMP

	NOTURNA
	EXTRA
	FIMDESEMANA
	FERIADO
}

function REGISTRO {

	PONTEIRO
	

	#SEC=$(("$TIMESTAMP" - "$HOJE"))

	OBJ=`cat $FILE`

	ENTRADAS=`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"]["'$DATA'"] | .registros | keys[]' | wc -l`
        
	SENTIDO=`echo $OBJ | jq -r '.meta.sentido'`
      	
	if [ -z "$SENTIDO"  ];then 
		OBJ=`echo $OBJ | jq '. += {"meta":{}}'`
		OBJ=`echo $OBJ | jq '.["'$ANO'"] += {"sumario":{}}'`
	fi
	
	if [ -z $SENTIDO ];then
		SENTIDO="entrada"
	else
		if [ $SENTIDO == "entrada" ];then
			SENTIDO="saida"
		else
			SENTIDO="entrada"
		fi
	fi
	#echo "$OBJ" > $FILE
	
	PLANTAO
	
	#echo "$OBJ" > $FILE

	
	
	OBJ=`echo $OBJ | jq '.["'$ANO'"]["'$MES'"] += {"sumario":{}}'`

	OBJ=`echo $OBJ | jq '.["'$ANO'"]["'$MES'"]["'$DATA'"].registros += {"'$TIMESTAMP'":{"timestamp":"'$TIMESTAMP'","hora":"'$HORA'","sentido":"'$SENTIDO'","mensagem":"'$MSG'"}}'`
       	
	ENTRADAS=`echo $OBJ | jq -r '.["'$ANO'"]["'$MES'"]["'$DATA'"] | .registros | keys[]' | wc -l`
	
	#echo "$OBJ" > $FILE

	SUMARIO
	
	OBJ=`echo $OBJ | jq '.["'$ANO'"]["'$MES'"]["'$DATA'"] += {"sumario":{"sentido":"'$SENTIDO'","registros":"'$ENTRADAS'","ultimo_registro":"'$ULTIMO'","virada":"'$VIRADA'","em_expediente":"'$DENTRO'","fora_expediente":"'$FORA'","extra":"'$EX'","horas_extras":"'$EXTRAS'","noturno":"'$N'","dia_da_semana":"'$DIA'","jornada":"'$SALDO'","horas_trabalhadas":"'$TRABALHADAS'","intervalo":"'$INTERVALO'","horas_noturnas":"'$NOTURNO'","fim_de_semana":"'$FDS'","saldo_feriados":"'$FERIADO'"}}'`
	
	MENSAL
	
	#OBJ=`echo $OBJ | jq '.["'$ANO'"]["'$MES'"] += {"sumario":{"ultimo_registro":"'$ULTIMO'","viradas":"'$VI'","extra":"'$EXT'","noturno":"'$NO'","saldo":"'$SD'","fim_de_semana":"'$FS'","feriado":"'$FE'"}}'`
	OBJ=`echo $OBJ | jq '.["'$ANO'"]["'$MES'"] += {"sumario":{"ultimo_registro":"'$ULTIMO'","viradas":"'$VI'","extra":"'$EXT'","noturno":"'$NO'","jornada":"'$SALDOMENSAL'","fim_de_semana":"'$FS'","saldo_feriados":"'$FE'","carga_mensal":"'$CARGAMENSAL'","dias_trabalhados":"'$DIASTRABALHADOS'","mes":{"dias":"'$DIAS'","dias_uteis":"'$UTIL'","feriados":"'$FERIADOS'","feriados_semana":"'$FERIADOUTIL'","horas":"'$HOR'"}}}'`
	
	#echo "$OBJ" > $FILE

	ANUAL

	OBJ=`echo $OBJ | jq '.["'$ANO'"] += {"sumario":{"viradas":"'$VIA'","extra":"'$EXTA'","noturno":"'$NOA'","jornada":"'$SDA'","fim_de_semana":"'$FSA'","saldo_feriados":"'$FEA'"}}'`
	
	OBJ=`echo $OBJ | jq '. += {"meta":{"sentido":"'$SENTIDO'","ultimo_registro":"'$ULTIMOREGISTRO'"}}'`

	echo "$OBJ" > $FILE
}

function PONTO {
	
	if [ -z $DATA  ];then
		TIMESTAMP=`date +%s`
	else
		TIMESTAMP=$(date +%s -d"$DATA $HORA")
	fi
	
	REGISTRO

}

function TESTE {
	
	echo ""
	echo "TIMESTAMP: $TIMESTAMP"
	echo "HOJE: $HOJE"
	echo "ALVO: $ALVO"
	echo "DATA: $DATA"
	echo "ANO: $ANO"
	echo "MES: $MES"
	echo "HORA: $HORA"
	echo "ONTEM: `date -d@$TIMESTAMP`"
	echo ""
	echo "RANGE: $RANGE"
	echo "PENULTIMO: $PENULTIMO"
	echo "ULTIMO: $ULTIMO"
	echo "ENTRADAS: $ENTRADAS"
	echo "SENTIDO: $SENTIDO"
	echo "REGISTROS:"
	echo "$REGISTROS"
	echo ""
	echo "DENTRO: $DENTRO"
	echo "FORA: $FORA"
	echo "SALDO: $SALDO"
	echo ""
	echo "DIFF: $DIFF"
	echo "VIRADA: $VIRADA"
	echo ""
}

#clear

if [ "$1" == "-i" ] ;then
        MSG="$2"
	MSG=$(echo "$MSG" | tr ' ' '_')
	DATA="$3"
        HORA="$4"
	if [ -z $5  ];then
		VIRADA=0
	else
		VIRADA="$5"
	fi
	PONTO
fi
if [ "$1" == "-r" ] ;then
        TIMESTAMP="$2"
        REMOVE
fi
if [ "$1" == "-c" ] ;then
        CALC
fi

TESTE

#cat $FILE | jq
