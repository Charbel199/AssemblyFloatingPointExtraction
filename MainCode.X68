                ORG     $1000
Input_1         DC.L $3F000000
Input_2         DC.L $3F000000
Exponent_Bits   DC.W $8
Product         DS.L 1
Sign_1          DS.W 1
Exponent_1      DS.L 1
Mantissa_1      DS.L 1
Sign_2          DS.W 1
Exponent_2      DS.L 1
Mantissa_2      DS.L 1


                ORG $2000
Subroutine_1    LINK A0,#-4 **opening a stack frame maybe for bias

                MOVEM.L D1-D4/A1,-(SP) **should store the used ones

                CLR.L D2 **Clear D2
                **all LEA +4 since based on A0 (base of stackframe)

                LEA (26,A0),A1 **26 not 24to only get the word
                MOVE.W (A1),A1 **Original number address
                MOVE.L (A1),D1 **Original number
                
                BPL.S POSITIVE
                
NEGATIVE        MOVEQ #1,D2 **Storing sign in register
            
                **Maybe instead of LEA directly move.L to register
POSITIVE        LEA (22,A0),A1 **22 not 20 to only get the word
                MOVE.W (A1),A1 **Number of exponent bits address
                MOVE.W (A1),D3 ** number of exponent bits
                
        
                
                LEA (18,A0),A1 **18 not 16 to only get the word
                MOVE.W (A1),A1 **Address for sign
          
                
                MOVE.W D2,(A1) **Storing sign in memory
             
                
                **Until this point: The sign is stored in memory
                        **          D1 has the original number
                        **          D3 has the number of exponen bits
                        **          D2 was used to get the sign

                
                
                
                MOVEQ #31,D4 **32 bit number - 1 for sign
                SUB.W D3,D4 **Storing the number of mantissa bits in D4(31 - number of exponent bits)
 
                        **          D4 was used to get the number of mantissa bits
 
                SUBQ #1,D3 ** D3 has become number of exponent bits - 1
                MOVEQ #1,D2
                ASL.L D3,D2 **2^(number of exponent bits -1)-1
                SUB.L #1,D2 **D2 is the bias
                
                        **          D2 has now the the bias MAYBE STORE IT IN LINK ?
                                                                                
                MOVE.L D1,-(SP) **Duplicating original number and storing it on the stack
          
             
                ADDQ #2,D3  **number of exponents bits + 1 (Sign)
                ASL.L D3,D1 **D6 is our final mantissa (Shifted the mantissa to the left by the number of exponents bits + 1     

                                      
                LEA (10,A0),A1 **6 not 4 to only get the word
                MOVE.W (A1),A1
                
                MOVE.L D1,(A1) **Mantissa stored
                
                
                MOVE.L (SP)+,D1 **Fetching the original number duplicate from the stack
                
                AND.L #$7FFFFFFF,D1 **Set MSB to 0 (For ASR)
                ASR.L D4,D1 **Moving our exponent by the number of mantissa bits to the right
                SUB.L D2,D1 **Removing the bias from it
                
                LEA (14,A0),A1 **14 not 12 to only get the word
                MOVE.W (A1),A1
                
                MOVE.L D1,(A1) **Exponent stored
                
                MOVEM.L (SP)+,D1-D4/A1
                UNLK A0
                RTS            
               
               
 **TEST: Store bias in stack frame and reuse D2              
               
               
               
               
               
               
               **Shouldn't forget to store registers
                ORG $3000
Subroutine_2    MOVEM.L D1-D7/A1-A6,-(SP) **should store the used ones

                MOVEA.L (68,SP),A1 **Address of Input 1
                MOVEA.L (64,SP),A2 **Address of Input 2
                MOVEA.L (60,SP),A3 **Address of number of exponent bits
                MOVEA.L (56,SP),A6 **Address of product result
                          

                **Preparing stack frame for subroutine 1     
                LINK A0,#-20
              
                
                MOVE.L A1,(-4,A0) **Address of input 1 on stack
                MOVE.L A3,(-8,A0) **Address of number of exponent bits on stack
                LEA (-12,A0),A4
                MOVE.L A4,(-12,A0) **Storing sign
                LEA (-16,A0),A4
                MOVE.L A4,(-16,A0) **Sotring exponent
                LEA (-20,A0),A4
                MOVE.L A4,(-20,A0) **Storing mantissa
                
                
                BSR Subroutine_1
                **Stack is now pointing at the top of the stack frame(Where the mantissa is)
                
                **Testing if subroutine performed correctly
                MOVE.L (-12,A0),D0 **sign1
                MOVE.L (-16,A0),D1 **exponent1
                MOVE.L (-20,A0),D2 **mantissa1
                
                
                **Preparing stack frame for subroutine 1 
                LINK A5,#-20
                
                MOVE.L A2,(-4,A5) **Address of input 2 on stack
                MOVE.L A3,(-8,A5) **Address of number of exponent bits on stack
                LEA (-12,A5),A4
                MOVE.L A4,(-12,A5) **Storing sign 
                LEA (-16,A5),A4
                MOVE.L A4,(-16,A5) **Sotring exponent 
                LEA (-20,A5),A4
                MOVE.L A4,(-20,A5) **Storing mantissa 
                
                BSR Subroutine_1
                
                **Testing if subroutine performed correctly
                MOVE.L (-12,A5),D3 **sign2
                MOVE.L (-16,A5),D4 **exponent2
                MOVE.L (-20,A5),D5 **mantissa2
                
                **Logic of multiplication:
                
                EOR.B D0,D3 
                ADD.L D1,D4
                
                **Shifted by 1 to add the hidden bit, then shifted by 16 (To take a word space)
                ASR.L #1,D2
                ASR.L #1,D5
                OR.L #$80000000,D2
                OR.L #$80000000,D5
                
                
                
                MOVE.B #16,D7
                ASR.L D7,D2
                ASR.L D7,D5
                
                
                
                
                MULU D2,D5
                BPL POS
NEG             ASL.L #1,D5
                ADD.L #1,D4
                BRA ENDOFSUBROUTINE2
                
POS             ASL.L #2,D5
                

**Only thing left to do is reconstruct the product
** new test sign in D3, exponent in D4, mantissa in D5
ENDOFSUBROUTINE2              MOVE.B #9,D7 **Shift by number of exponent bits + 1

                              ASR.L D7,D5
                              ADD.L #127,D4 **Make adding bias general
                              MOVE.B #23,D7 **Shift by number of mantissa bits
                              ASL.L D7,D4
                              OR.L D4,D5
                              ** sign still not done
                              
                              **Should store it in product location in memory
                              LEA (A6),A6
                              MOVE.L D5,(A6)
                              UNLK A5
                              UNLK A0
                              MOVEM.L (SP)+,D1-D7/A1-A6

     










                  RTS
                
                














                ORG $400


START           MOVEA.L #$4000,A7
                PEA Input_1
                PEA Exponent_Bits
                PEA Sign_1
                PEA Exponent_1
                PEA Mantissa_1
                
                **Testing if registers are still the same
                MOVE.L #$12309,D1 
                MOVE.L #$1234,D2
                MOVE.L #$1234,D3
                MOVE.L #$1234,D4
                MOVEA.L #$1230,A1
                
                
                BSR Subroutine_1
                LEA ($14,SP),SP
                **Stack pointer back to normal
                
                
                
                **PART 2:
                
                
                MOVEA.L #$5000,A7
                PEA Input_1
                PEA Input_2
                PEA Exponent_Bits
                PEA Product
                BSR Subroutine_2
                **Return stack as it was
                LEA ($10,SP),SP
                **Stack pointer back to normal





                END START
                
                

                        












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
