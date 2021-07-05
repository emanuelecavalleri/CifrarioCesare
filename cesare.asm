	.data
	
	benvenuto:    		.asciiz "Scegli un'opzione! 1: Cifratura - 2: Decifrazione - 0: Esci\n> "
	messaggio_chiave:	.asciiz "Inserisci la chiave (ovviamente maggiore di zero):\n> "
	messaggio_cifr:   	.asciiz "La cifratura del testo con chiave "
	messaggio_decifr:    	.asciiz "La decifratura del testo con chiave "
	messaggio_testo:    	.asciiz "Inserisci il testo:\n> "
	messaggio_output:    	.asciiz " e' la seguente:\n"
	continuare:    		.asciiz "Premi '1' per continuare, '0' per uscire:\n>"
	arrivederci:    	.asciiz "A presto!\n"
	errore: 		.asciiz "Testo non valido!\n"
	endl:         		.asciiz "\n"

	string:       		.space 256

	errore_chiave: 		.asciiz "Input non valido!\n" 
	ecode: 			.word 0x20

	.ktext 0x80000180
	
	mfc0 $k0, $13
	mfc0 $k1, $14
	andi $k0, $k0, 0x003c
	lw $t0, ecode
	li $v0, 4
	la $a0, errore_chiave
	syscall
	la $k1, main
	jr $k1

	.globl main
	
	.text

main:  

# $s0 contiene il codice dell'operazione da eseguire
# $s1 contiene la chiave
# $s2 contiene la lunghezza della stringa
# $s3 contiene l'indirizzo della stringa di output   
                      
	li $v0, 4
  	la $a0, benvenuto
  	syscall			# Messaggio di benvenuto con opzioni

  	li $v0, 5                     
  	syscall			# Leggi l'opzione richiesta

  	beq $v0, $zero, esci    # = 0 : Esci
  	bltz $v0, main          # < 0 : main
  	bgt $v0, 2, main        # > 2 : main
  
  	addi $s0, $v0, 0        # Salva in $s0

chiave:   
                    
 	li $v0, 4                     
  	la $a0, messaggio_chiave             
  	syscall			# Chiedi la chiave

  	li $v0, 5
  	syscall			# Leggi la chiave

  	li $t0, 26                    
  	div $v0, $t0
  	mfhi $t1                # Salva $v0 (chiave) % 26 in $t1

  	blez  $t1, chiave	# La chiave deve essere > 0
  	addi $s1, $t1, 0        # Salva la chiave in $s1

testo:   
                 
  	li $v0, 4
  	la $a0, messaggio_testo
  	syscall			# Chiedi il testo

  	li $v0, 8
  	la $a0, string
  	li $a1, 255
  	syscall			# Leggi il testo (max 256 caratteri)

  	la $a0, string
  	jal strlen

  	beq $v1, 0, stringa_valida
  	j testo

stringa_valida:

  	addi $s2, $v0, 0        # Salva strlen(string) in $s2

allocazione:

 	li $v0,9                     
  	addi $a0, $s2, 1            
  	syscall			# Alloca memoria per salvare la stringa di output

  	addi $s3, $v0, 0

seleziona_opzione:

 	beq $s0, 1, opzione_cifratura
  	beq $s0, 2, opzione_decifratura
  	j main

opzione_decifratura:

  	add $t0, $s1, $s1            
  	sub $s1, $s1, $t0       # Calcola -chiave per decifrare
	
  	li $v0, 4
  	la $a0, messaggio_decifr
  	syscall			# Stampa messaggio decifratura

  	li $v0, 1
  	addi $a0, $s1, 0
  	syscall			# Stampa -chiave

 	j invoca_cifratura

opzione_cifratura:

  	li $v0, 4
  	la $a0, messaggio_cifr
  	syscall			# Stampa messaggio cifratura

  	li $v0, 1
  	addi $a0, $s1, 0
  	syscall			# Stampa la chiave

invoca_cifratura:    
            
  	addi $a0, $s2, 0              
  	li $a1, 0                   
  	addi $a2, $s3, 0             
  	jal cifratura		# Cifratura(strlen(string), indice attuale, indirizzo stringa output)

  	j output

output:  
                       
  	li $v0, 4
  	la $a0, messaggio_output
  	syscall			# Stampa messaggio di output

  	addi $a0, $s3, 0
  	li $v0, 4
  	syscall			# Stampa stringa di output

  	li $a0, 4
  	la $a0, endl		# Stampa \n
  	syscall

  	li $v0, 4                    
  	la $a0, continuare
  	syscall			# Chiedi se l'utente vuole continuare ('1')
	
  	li $v0, 5                    
  	syscall			# Leggi se vuole continuare ('1')

  	addi $t0, $v0, 0        # Salva in $t0 la risposta

  	beq $t0, 1, main        # $t0 = 1 : main

esci: 
                        
  	li $v0, 4
  	la $a0, arrivederci
  	syscall			# Stampa messaggio arrivederci

  	li $v0, 10
  	syscall			# Termina esecuzione

cifratura: 

# Algoritmo di cifratura:
#     testo_cifrato = ((testo_in_chiaro - offset_carattere_ASCII) + chiave) % 26) + offset_carattere_ASCII
#     testo_in_chiaro = ((testo_cifrato - offset_carattere_ASCII) - chiave) % 26) + offset_carattere_ASCII
#
# $a0 contiene strlen(string)
# $a1 contiene l'indice attuale
# $a2 contiene l'indirizzo della stringa di output
#
# $v0 conterrà strlen(string)
# $v1 conterrà un eventuale errore o meno (-1/0)
  
	addi $sp, $sp -16            
  	sw $a0, 0($sp)           # strlen(string)
  	sw $a1, 4($sp)           # Indice attuale
  	sw $a2, 8($sp)           # Indirizzo stringa di output
  	sw $ra, 12($sp)          # Indirizzo return

  	li $t5, 0                     
  	sb $t5, 0($a2)           # Scrivi \0 nella posizione attuale

  	bge $a1, $a0, cifratura_end

  	addi $t1, $a0, 0     		       

  	lb $a0, string($a1)

	jal esclamativo
  	beq $v0, 1, cifratura_esclamativo
  	
  	jal interrogativo
  	beq $v0, 1, cifratura_interrogativo
  	
  	jal punto
  	beq $v0, 1, cifratura_punto
  	
  	jal virgola
  	beq $v0, 1, cifratura_virgola

  	jal spazio
  	beq $v0, 1, cifratura_spazio

  	jal char_offset           # Salva l'offset in $v0
  	addi $t2, $v0, 0          # Salva offset in $t2

  	algoritmo_cifratura:
  	
    		li $t7, 26                  # $t7 = modulo (26)
    		sub $t3, $a0, $t2           # $t3 = carattere - offset
    		add $t3, $t3, $s1           # $t3 += chiave
    		div $t3, $t7                # $t3 % modulo (26)
    		mfhi $t3
    		add $t3, $t3, $t2           # $t3 += offset

   	 	sb $t3, 0($a2)

  	cifratura_next_char:
  	
   		addi $a0, $t1, 0
    		addi $a1, $a1, 1
    		addi $a2, $a2, 1
    		jal cifratura

  	cifratura_end:
  	
    		lw $a0, 0($sp)
    		lw $a1, 4($sp)
    		lw $a2, 8($sp)
    		lw $ra, 12($sp)
    		addi $sp, $sp, 16
    		jr $ra

  	cifratura_spazio:
  	
    		li $t5, 32
    		sb $t5, 0($a2)
    		j cifratura_next_char
    		
    	cifratura_esclamativo:
  	
    		li $t5, 33
    		sb $t5, 0($a2)
    		j cifratura_next_char	
    		
    	cifratura_interrogativo:
  	
    		li $t5, 63
    		sb $t5, 0($a2)
    		j cifratura_next_char	
    		
    	cifratura_punto:
  	
    		li $t5, 46
    		sb $t5, 0($a2)
    		j cifratura_next_char	
    		
    	cifratura_virgola:
  	
    		li $t5, 44
    		sb $t5, 0($a2)
    		j cifratura_next_char																								

char_offset:

# L'offset e':
#
#   Cifratura:
#     'a': se il carattere è minuscolo
#     'A': se il carattere è maiuscolo
#
#   Decifratura:
#     'z': se il carattere è minuscolo
#     'Z': se il carattere è maiuscolo
#
# $a0 contiene il carattere
#
# $v0 conterrà l'offset

	addi $sp, $sp, -8
  	sw $a0, 0($sp)
  	sw $ra, 4($sp)
  
  	jal minuscolo

  	lw $a0, 0($sp)
  	lw $ra, 4($sp)
  	addi $sp, $sp, 8

  	bne $v0, 1, cifratura_maiuscolo
  
  	cifratura_minuscolo:
  	
    		beq $s0, 2, decifra_minuscolo
    		li $v0, 97
    		jr $ra

  	decifra_minuscolo:
  
    		li $v0, 122
   		jr $ra

  	cifratura_maiuscolo:
   		beq $s0, 2, decifra_maiuscolo
    		li $v0, 65
    		jr $ra

  	decifra_maiuscolo:
    		li $v0, 90
    		jr $ra

strlen:

# strlen conta la lunghezza della stringa e dice se è valida o meno.
# Una stringa valida contiene qualsiasi carattere che sia una
# lettera, un punto esclamativo, un punto interrogativo, un punto,
# una virgola o uno spazio.
#
# $a0 contiene la stringa da validare
#
# $v0 conterrà la lunghezza della stringa
# $v1 conterrà la presenza di un errore o meno (-1/0)

	addi $sp, $sp, -8
  	sw $a0, 0($sp)
  	sw $ra, 4($sp)

  	li $t0, 0
  	li $t1, 0
  	addi $t2, $a0, 0
  	li $t3, 10		# New Line            

  	strlenloop:
  	
    		lb $t1, 0($t2)
    		beqz $t1, strlenexit    	# $t1 = \00 ?
   		beq $t1, $t3 strlenexit 	# $t1 = \n  ?

    		addi $a0, $t1, 0        	# Salva in $a0 il carattere
    		jal valid_char        		# return 1 if valido
    		bne $v0, 1, strlenerror

    		addi $t2, $t2, 1
    		addi $t0, $t0, 1
    		j strlenloop

  	strlenexit:
  	
    		lw $a0, 0($sp)
    		lw $ra, 4($sp)
    		addi $sp, $sp, 8

    		addi $v0, $t0, 0
    		li $v1, 0
    		jr $ra

  	strlenerror:
  	
    		lw $a0, 0($sp)
    		lw $ra, 4($sp)
    		addi $sp, $sp, 8

    		li $v0, 4
    		la $a0, errore
    		syscall

    		li $v0, -1
    		li $v1, -1
    		jr $ra


valid_char:

# $a0 contiene il carattere
#
# $v0 conterrà 1: carattere valido
#              0: carattere non valido

	addi $sp, $sp, -8
  	sw $a0, 0($sp)
  	sw $ra, 4($sp)

  	jal lettera
  	beq $v0, 1, valid_char_found

  	jal spazio
  	beq $v0, 1, valid_char_found
  	
  	jal esclamativo
  	beq $v0, 1, valid_char_found
  	
  	jal interrogativo
  	beq $v0, 1, valid_char_found
  	
  	jal punto
  	beq $v0, 1, valid_char_found
  	
  	jal virgola
  	beq $v0, 1, valid_char_found

  	lw $a0, 0($sp)
  	lw $ra, 4($sp)
  	addi $sp, $sp, 8

  	li $v0, 0
  	jr $ra

  	valid_char_found:
  	
    		lw $a0, 0($sp)
    		lw $ra, 4($sp)
    		addi $sp, $sp, 8

    		li $v0, 1
   		jr $ra

lettera:

# $a0 contiene il carattere
#
# $v0 conterrà 1: lettera valida
#              0: lettera non valida

	addi $sp, $sp, -8
  	sw $a0, 0($sp)  
  	sw $ra, 4($sp)

  	jal minuscolo
  	beq $v0, 1, valid_letter
  	blt $v0, 0, notvalid_letter

 	jal maiuscolo
  	beq $v0, 1, valid_letter
  	blt $v0, 0, notvalid_letter

  	notvalid_letter:
  	
    		lw $a0, 0($sp)
    		lw $ra, 4($sp)
    		addi $sp, $sp, 8

    		li $v0, 0
    		jr $ra

  	valid_letter:
  	
    		lw $a0, 0($sp)
    		lw $ra, 4($sp)
    		addi $sp, $sp, 8

    		li $v0, 1
    		jr $ra

spazio:

# $a0 contiene il carattere
#
# $v0 conterrà 1: spazio
#              0: non spazio

	bne $a0, 32, not_spazio
  
  	li $v0, 1
  	jr $ra

  	not_spazio:
    		li $v0, 0
    		jr $ra

esclamativo:

# $a0 contiene il carattere
#
# $v0 conterrà 1: esclamativo
#              0: non esclamativo

	bne $a0, 33, not_esclamativo
  
  	li $v0, 1
  	jr $ra

  	not_esclamativo:
    		li $v0, 0
    		jr $ra
    		
interrogativo:

# $a0 contiene il carattere
#
# $v0 conterrà 1: interrogativo
#              0: non interrogativo

	bne $a0, 63, not_interrogativo
  
  	li $v0, 1
  	jr $ra

  	not_interrogativo:
    		li $v0, 0
    		jr $ra   
    		
punto:

# $a0 contiene il carattere
#
# $v0 conterrà 1: punto
#              0: non punto

	bne $a0, 46, not_punto
  
  	li $v0, 1
  	jr $ra

  	not_punto:
    		li $v0, 0
    		jr $ra   
    		
virgola:

# $a0 contiene il carattere
#
# $v0 conterrà 1: virgola
#              0: non virgola

	bne $a0, 44, not_virgola
   
  	li $v0, 1
  	jr $ra

  	not_virgola:
    		li $v0, 0
    		jr $ra       		    		 		 		    		 		 		

minuscolo:

# $a0 contiene il carattere
#
# $v0 conterrà 1: minuscolo
#              0: non minuscolo
#             -1: non una lettera

	blt $a0, 97, not_minuscolo
  	bgt $a0, 122, minuscolo_error

  	li $v0, 1
  	jr $ra
  	
  	minuscolo_error:
  	
    		li $v0, -1
    		jr $ra
    		
  	not_minuscolo:
   		li $v0, 0
    		jr $ra
    		
maiuscolo:

# $a0 contiene il carattere
#
# $v0 conterrà 1: maiuscolo
#              0: non maiuscolo
#             -1: non una lettera

	blt $a0, 65, maiuscolo_error
  	bgt $a0, 90, not_maiuscolo

  	li $v0, 1
  	jr $ra
  	
  	maiuscolo_error:
  	
    		li $v0, -1
    		jr $ra
    		
  	not_maiuscolo:
  	
    		li $v0, 0
    		jr $ra
