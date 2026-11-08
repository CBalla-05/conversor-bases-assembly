; ============================================================
; ESPOL - Organizacion de Computadores
; PROYECTO ASSEMBLY: Conversor de Bases Numericas
; Entorno: emu8086 / Assembly x86 de 16 bits
; ============================================================

; ============================================================
; SEGMENTO DE PILA
; ============================================================
PILA_SEG SEGMENT STACK
    DB 100h DUP(?)
PILA_SEG ENDS

; ============================================================
; SEGMENTO DE DATOS
; ============================================================
DATA_SEG SEGMENT
    ; ---------------------------------------------------------
    ; Estructura para lectura de cadena con INT 21h, funcion 0Ah
    ; ---------------------------------------------------------
    IN_MAX  DB 20                 ; maximo de caracteres permitidos
    IN_LEN  DB ?                  ; caracteres realmente ingresados (llenado por DOS)
    IN_STR  DB 21 DUP('$')        ; buffer donde se guarda la cadena ingresada

    ; ---------------------------------------------------------
    ; Variables de estado del programa
    ; ---------------------------------------------------------
    modo_actual  DB 0             ; 0 = decimal, 1 = binario, 2 = hexadecimal
    valor_leido  DW 0             ; valor numerico ya validado (0-255)
    DIEZ         DW 10            ; constante usada por MUL en VALIDAR_DEC

    ; ---------------------------------------------------------
    ; Buffers de resultado (cadenas ASCII terminadas en '$')
    ; ---------------------------------------------------------
    bin_out DB '00000000$'        ; resultado binario (8 caracteres + '$')
    hex_out DB '00$'              ; resultado hexadecimal (2 caracteres + '$')
    dec_out DB '0000$'            ; resultado decimal (hasta 3 caracteres + '$')

    ; ---------------------------------------------------------
    ; Mensajes de texto (cada linea lleva su propio DB)
    ; ---------------------------------------------------------
    msg_titulo        DB 13,10,'=== CONVERSOR DE BASES NUMERICAS ===',13,10,'$'

    msg_menu          DB 13,10,'1. Decimal      -> Binario',13,10
                      DB '2. Decimal      -> Hexadecimal',13,10
                      DB '3. Binario      -> Decimal',13,10
                      DB '4. Hexadecimal  -> Decimal',13,10
                      DB '5. Salir',13,10
                      DB 'Seleccione una opcion: $'

    msg_opc_invalida  DB 13,10,'Opcion invalida. Intente de nuevo.',13,10,'$'
    msg_pedir_dec     DB 13,10,'Ingrese un numero decimal (0-255): $'
    msg_pedir_bin     DB 13,10,'Ingrese un numero binario (hasta 8 bits, solo 0/1): $'
    msg_pedir_hex     DB 13,10,'Ingrese un numero hexadecimal (hasta 2 digitos, 0-9 A-F): $'
    msg_error_entrada DB 13,10,'>> Entrada invalida (formato o rango incorrecto). Intente de nuevo.',13,10,'$'
    msg_resultado_bin DB 13,10,'Resultado en BINARIO: $'
    msg_resultado_hex DB 13,10,'Resultado en HEXADECIMAL: $'
    msg_resultado_dec DB 13,10,'Resultado en DECIMAL: $'
    msg_salir         DB 13,10,'Programa finalizado. Hasta pronto.',13,10,'$'
    nl                DB 13,10,'$'
DATA_SEG ENDS

; ============================================================
; SEGMENTO DE CODIGO
; ============================================================
CODE_SEG SEGMENT
    ASSUME CS:CODE_SEG, DS:DATA_SEG, SS:PILA_SEG

; ============================================================
; INICIO DEL PROGRAMA
; ============================================================
START:
    ; Inicializar el segmento de datos (sin usar @DATA)
    MOV AX, DATA_SEG
    MOV DS, AX

    LEA DX, msg_titulo
    MOV AH, 09h
    INT 21h

; ============================================================
; BUCLE PRINCIPAL DEL PROGRAMA
; ============================================================
MAIN_LOOP:
    CALL MENU_PRINCIPAL        ; AL = opcion numerica elegida

    CMP AL, 1
    JE  OPCION_1
    CMP AL, 2
    JE  OPCION_2
    CMP AL, 3
    JE  OPCION_3
    CMP AL, 4
    JE  OPCION_4
    CMP AL, 5
    JE  OPCION_5

    LEA DX, msg_opc_invalida
    MOV AH, 09h
    INT 21h
    JMP MAIN_LOOP

OPCION_1:                       ; Decimal -> Binario
    MOV modo_actual, 0
    CALL LEER_NUMERO
    MOV BX, valor_leido
    CALL DEC_A_BIN
    LEA DX, msg_resultado_bin
    LEA SI, bin_out
    CALL MOSTRAR_RESULTADO
    JMP MAIN_LOOP

OPCION_2:                       ; Decimal -> Hexadecimal
    MOV modo_actual, 0
    CALL LEER_NUMERO
    MOV BX, valor_leido
    CALL DEC_A_HEX
    LEA DX, msg_resultado_hex
    LEA SI, hex_out
    CALL MOSTRAR_RESULTADO
    JMP MAIN_LOOP

OPCION_3:                       ; Binario -> Decimal
    MOV modo_actual, 1
    CALL LEER_NUMERO
    MOV BX, valor_leido
    CALL BIN_A_DEC
    LEA DX, msg_resultado_dec
    LEA SI, dec_out
    CALL MOSTRAR_RESULTADO
    JMP MAIN_LOOP

OPCION_4:                       ; Hexadecimal -> Decimal
    MOV modo_actual, 2
    CALL LEER_NUMERO
    MOV BX, valor_leido
    CALL HEX_A_DEC
    LEA DX, msg_resultado_dec
    LEA SI, dec_out
    CALL MOSTRAR_RESULTADO
    JMP MAIN_LOOP

OPCION_5:                       ; Salir
    LEA DX, msg_salir
    MOV AH, 09h
    INT 21h
    MOV AH, 4Ch                 ; Terminar programa
    INT 21h


; ============================================================
; PROC: MENU_PRINCIPAL
; Objetivo: mostrar el menu de opciones y leer la seleccion del
;           usuario como un solo caracter.
; Entrada:  Ninguna
; Salida:   AL = valor numerico de la opcion (0 si no es digito)
; Modifica: AX, DX
; ============================================================
MENU_PRINCIPAL PROC
    PUSH CX
    PUSH DX
    PUSH SI

    LEA DX, msg_menu
    MOV AH, 09h
    INT 21h

    ; Lectura bufferizada (en vez de INT 21h/01h) para poder validar
    ; la longitud real ingresada y no solo el primer caracter tecleado
    LEA DX, IN_MAX
    MOV AH, 0Ah
    INT 21h                  ; DOS llena IN_LEN e IN_STR

    LEA DX, nl
    MOV AH, 09h
    INT 21h

    MOV CL, IN_LEN
    MOV CH, 0
    LEA SI, IN_STR

    CMP CX, 1
    JNE MENU_OPCION_INVALIDA  ; se exige exactamente 1 caracter

    MOV AL, [SI]
    CMP AL, '1'
    JB  MENU_OPCION_INVALIDA
    CMP AL, '5'
    JA  MENU_OPCION_INVALIDA

    SUB AL, 30h               ; convertir ASCII -> valor numerico (1-5)
    JMP MENU_FIN

MENU_OPCION_INVALIDA:
    MOV AL, 0                 ; no coincide con ninguna opcion valida (1-5)

MENU_FIN:
    POP SI
    POP DX
    POP CX
    RET
MENU_PRINCIPAL ENDP


; ============================================================
; PROC: LEER_NUMERO
; Objetivo: leer una cadena por teclado (INT 21h, funcion 0Ah),
;           validarla caracter a caracter segun la base indicada
;           en 'modo_actual' y convertirla a su valor numerico.
;           Si la entrada es invalida, muestra un error y
;           vuelve a solicitar el dato (no termina el programa).
; Entrada:  modo_actual = 0 (decimal) / 1 (binario) / 2 (hex)
; Salida:   BX = valor numerico validado (0-255)
;           valor_leido = copia del valor numerico
; Modifica: AX, BX, CX, DX, SI
; ============================================================
LEER_NUMERO PROC

REINTENTAR_LECTURA:
    MOV AL, modo_actual
    CMP AL, 0
    JE  PROMPT_DEC
    CMP AL, 1
    JE  PROMPT_BIN
    JMP PROMPT_HEX

PROMPT_DEC:
    LEA DX, msg_pedir_dec
    JMP LEER_INPUT
PROMPT_BIN:
    LEA DX, msg_pedir_bin
    JMP LEER_INPUT
PROMPT_HEX:
    LEA DX, msg_pedir_hex

LEER_INPUT:
    MOV AH, 09h
    INT 21h

    ; Lectura con INT 21h funcion 0Ah como exige la rubrica
    LEA DX, IN_MAX
    MOV AH, 0Ah
    INT 21h                  ; DOS llena IN_LEN e IN_STR

    LEA DX, nl
    MOV AH, 09h
    INT 21h

    MOV CL, IN_LEN
    MOV CH, 0
    LEA SI, IN_STR

    CMP CX, 0
    JE  ENTRADA_INVALIDA      ; cadena vacia -> invalida

    ; --- validar longitud maxima segun la base ---
    MOV AL, modo_actual
    CMP AL, 0
    JNE CHECK_BIN_LEN
    CMP CL, 3                 ; decimal: maximo 3 digitos (0-255)
    JA  ENTRADA_INVALIDA
CHECK_BIN_LEN:
    CMP AL, 1
    JNE CHECK_HEX_LEN
    CMP CL, 8                 ; binario: maximo 8 bits
    JA  ENTRADA_INVALIDA
CHECK_HEX_LEN:
    CMP AL, 2
    JNE VALIDAR_DISPATCH
    CMP CL, 2                 ; hexadecimal: maximo 2 digitos
    JA  ENTRADA_INVALIDA

VALIDAR_DISPATCH:
    MOV BX, 0                 ; acumulador del valor numerico
    CMP AL, 0
    JE  VALIDAR_DEC
    CMP AL, 1
    JE  VALIDAR_BIN
    JMP VALIDAR_HEX

    ; --------------------------------------------------------
    ; Validacion y conversion: DECIMAL ('0'-'9')
    ; BX = BX*10 + digito   (usa MUL, segun requisito del proyecto)
    ; --------------------------------------------------------
VALIDAR_DEC:
LOOP_DEC:
    MOV AL, [SI]
    CMP AL, '0'
    JB  ENTRADA_INVALIDA
    CMP AL, '9'
    JA  ENTRADA_INVALIDA
    SUB AL, 30h               ; ASCII -> valor numerico (digito)
    MOV AH, 0
    PUSH AX                   ; guardar el digito mientras se usa MUL
    MOV AX, BX
    MUL DIEZ                  ; DX:AX = BX * 10
    MOV BX, AX
    POP AX
    ADD BX, AX                ; BX = BX*10 + digito
    INC SI
    LOOP LOOP_DEC

    CMP BX, 255
    JA  ENTRADA_INVALIDA       ; fuera de rango permitido
    JMP LECTURA_OK

    ; --------------------------------------------------------
    ; Validacion y conversion: BINARIO ('0' o '1')
    ; BX = BX*2 + bit   (usa SHL, equivalente a multiplicar por 2)
    ; --------------------------------------------------------
VALIDAR_BIN:
LOOP_BIN:
    MOV AL, [SI]
    CMP AL, '0'
    JE  BIN_ES_CERO
    CMP AL, '1'
    JE  BIN_ES_UNO
    JMP ENTRADA_INVALIDA
BIN_ES_CERO:
    SHL BX, 1
    JMP BIN_SIGUIENTE
BIN_ES_UNO:
    SHL BX, 1
    INC BX
BIN_SIGUIENTE:
    INC SI
    LOOP LOOP_BIN

    CMP BX, 255
    JA  ENTRADA_INVALIDA
    JMP LECTURA_OK

    ; --------------------------------------------------------
    ; Validacion y conversion: HEXADECIMAL ('0'-'9','A'-'F','a'-'f')
    ; BX = BX*16 + digito   (usa SHL x4, equivalente a multiplicar por 16)
    ; --------------------------------------------------------
VALIDAR_HEX:
LOOP_HEX:
    MOV AL, [SI]
    CMP AL, '0'
    JB  ENTRADA_INVALIDA
    CMP AL, '9'
    JBE HEX_DIGITO_NUM
    CMP AL, 'A'
    JB  ENTRADA_INVALIDA
    CMP AL, 'F'
    JBE HEX_DIGITO_MAYUS
    CMP AL, 'a'
    JB  ENTRADA_INVALIDA
    CMP AL, 'f'
    JBE HEX_DIGITO_MIN
    JMP ENTRADA_INVALIDA

HEX_DIGITO_NUM:
    SUB AL, 30h                ; AL - 30h -> 0..9
    JMP HEX_ACUMULAR
HEX_DIGITO_MAYUS:
    SUB AL, 37h                ; AL - 37h -> 10..15 ('A'-'F')
    JMP HEX_ACUMULAR
HEX_DIGITO_MIN:
    SUB AL, 57h                ; AL - 57h -> 10..15 ('a'-'f')

HEX_ACUMULAR:
    MOV AH, 0
    PUSH AX
    SHL BX, 1
    SHL BX, 1
    SHL BX, 1
    SHL BX, 1                  ; BX = BX * 16
    POP AX
    ADD BX, AX
    INC SI
    LOOP LOOP_HEX

    CMP BX, 255
    JA  ENTRADA_INVALIDA
    JMP LECTURA_OK

ENTRADA_INVALIDA:
    CALL MOSTRAR_ERROR
    JMP REINTENTAR_LECTURA

LECTURA_OK:
    MOV valor_leido, BX
    RET
LEER_NUMERO ENDP


; ============================================================
; PROC: DEC_A_BIN
; Objetivo: convertir un valor numerico (0-255) a su cadena
;           binaria de 8 caracteres.
; Entrada:  BX = valor numerico
; Salida:   bin_out = cadena binaria (8 caracteres + '$')
; Modifica: AX, BX, CX, SI
; ============================================================
DEC_A_BIN PROC
    PUSH AX
    PUSH CX
    PUSH SI

    MOV CX, 8
    LEA SI, bin_out
    ADD SI, 7                 ; apuntar al bit menos significativo (posicion 7)

DAB_LOOP:
    MOV AX, BX
    AND AX, 1                 ; extraer el bit menos significativo
    ADD AL, '0'                ; convertir a caracter '0' o '1'
    MOV [SI], AL
    DEC SI
    SHR BX, 1                  ; desplazar a la derecha (equivalente a /2)
    LOOP DAB_LOOP

    POP SI
    POP CX
    POP AX
    RET
DEC_A_BIN ENDP


; ============================================================
; PROC: DEC_A_HEX
; Objetivo: convertir un valor numerico (0-255) a su cadena
;           hexadecimal de 2 caracteres.
; Entrada:  BX = valor numerico
; Salida:   hex_out = cadena hexadecimal (2 caracteres + '$')
; Modifica: AX, BX, CX, SI
; ============================================================
DEC_A_HEX PROC
    PUSH AX
    PUSH CX
    PUSH SI

    MOV CX, 2
    LEA SI, hex_out
    ADD SI, 1                 ; apuntar al digito menos significativo

DAH_LOOP:
    MOV AX, BX
    AND AX, 0Fh                ; extraer los 4 bits menos significativos
    CMP AL, 9
    JA  DAH_LETRA
    ADD AL, '0'
    JMP DAH_GUARDAR
DAH_LETRA:
    ADD AL, 'A' - 10           ; convertir 10-15 a 'A'-'F'
DAH_GUARDAR:
    MOV [SI], AL
    DEC SI
    SHR BX, 1
    SHR BX, 1
    SHR BX, 1
    SHR BX, 1                  ; desplazar 4 bits (equivalente a /16)
    LOOP DAH_LOOP

    POP SI
    POP CX
    POP AX
    RET
DEC_A_HEX ENDP


; ============================================================
; PROC: BIN_A_DEC
; Objetivo: dado un valor ya parseado desde binario, generar
;           su representacion decimal en ASCII para mostrarla.
; Entrada:  BX = valor numerico (0-255), ya validado por LEER_NUMERO
; Salida:   dec_out = cadena decimal en ASCII
; Modifica: AX, BX, CX, DX, SI (a traves de NUM_A_CADENA_DEC)
; ============================================================
BIN_A_DEC PROC
    CALL NUM_A_CADENA_DEC
    RET
BIN_A_DEC ENDP


; ============================================================
; PROC: HEX_A_DEC
; Objetivo: dado un valor ya parseado desde hexadecimal, generar
;           su representacion decimal en ASCII para mostrarla.
; Entrada:  BX = valor numerico (0-255), ya validado por LEER_NUMERO
; Salida:   dec_out = cadena decimal en ASCII
; Modifica: AX, BX, CX, DX, SI (a traves de NUM_A_CADENA_DEC)
; ============================================================
HEX_A_DEC PROC
    CALL NUM_A_CADENA_DEC
    RET
HEX_A_DEC ENDP


; ============================================================
; PROC: NUM_A_CADENA_DEC (auxiliar)
; Objetivo: convertir un valor numerico de 16 bits (0-255) en su
;           cadena de digitos decimales ASCII. Usa DIV para
;           extraer digitos por resto y PUSH/POP para invertir.
; Entrada:  BX = valor numerico
; Salida:   dec_out = cadena resultante terminada en '$'
; Modifica: AX, BX, CX, DX, SI
; ============================================================
NUM_A_CADENA_DEC PROC
    MOV AX, BX
    MOV CX, 0                  ; contador de digitos generados

NCD_DIVIDIR:
    MOV DX, 0
    MOV BX, 10
    DIV BX                     ; AX = AX/10 ; DX = residuo (proximo digito)
    ADD DL, '0'                 ; convertir residuo a caracter ASCII
    PUSH DX                     ; apilar el digito para invertir su orden
    INC CX
    CMP AX, 0
    JNE NCD_DIVIDIR

    LEA SI, dec_out
NCD_ESCRIBIR:
    POP DX                      ; desapilar en orden inverso (MSB primero)
    MOV [SI], DL
    INC SI
    LOOP NCD_ESCRIBIR

    MOV BYTE PTR [SI], '$'
    RET
NUM_A_CADENA_DEC ENDP


; ============================================================
; PROC: MOSTRAR_RESULTADO
; Objetivo: imprimir en pantalla una etiqueta seguida del
;           resultado de la conversion.
; Entrada:  DX = offset del mensaje de etiqueta ('$'-terminado)
;           SI = offset de la cadena de resultado ('$'-terminada)
; Salida:   Ninguna
; Modifica: AX, DX
; ============================================================
MOSTRAR_RESULTADO PROC
    PUSH AX

    MOV AH, 09h
    INT 21h                    ; imprime la etiqueta (usa DX de entrada)
    MOV DX, SI
    INT 21h                    ; imprime el resultado (AH sigue en 09h)

    POP AX
    RET
MOSTRAR_RESULTADO ENDP


; ============================================================
; PROC: MOSTRAR_ERROR
; Objetivo: imprimir el mensaje de entrada invalida.
; Entrada:  Ninguna
; Salida:   Ninguna
; Modifica: AX, DX
; ============================================================
MOSTRAR_ERROR PROC
    PUSH AX
    PUSH DX

    LEA DX, msg_error_entrada
    MOV AH, 09h
    INT 21h

    POP DX
    POP AX
    RET
MOSTRAR_ERROR ENDP

CODE_SEG ENDS
END START