                ORG     $1000
Input_1         DC.L $C4040000
Input_2         DC.L $40001400
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


                **all LEA +4 since based on A0 (base of stackframe)

                LEA (26,A0),A1 **22 not 20 to only get the word
                MOVE.W (A1),A1 **Original number address
                MOVE.L (A1),D1 **Original number
                BPL.S POSITIVE
                 
NEGATIVE        MOVEQ #1,D2 **Storing sign in register
            
                
POSITIVE        LEA (22,A0),A1 **18 not 16 to only get the word
                MOVE.W (A1),A1 **Number of exponent bits address
                MOVE.W (A1),D3 ** number of exponent bits
                
        
                
                LEA (18,A0),A1 **14 not 12 to only get the word
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
                
                        **          D2 has now the the bias
                                                                                
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
                
                LEA (14,A0),A1 **10 not 8 to only get the word
                MOVE.W (A1),A1
                
                MOVE.L D1,(A1) **Exponent stored
                
                MOVEM.L (SP)+,D1-D4/A1
                UNLK A0
                RTS            
               
               
 **TEST: Store bias in stack frame and reuse D2              
               
               
                ORG $3000
Subroutine_2    RTS
                
                


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

                END START
                
                

                        


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
