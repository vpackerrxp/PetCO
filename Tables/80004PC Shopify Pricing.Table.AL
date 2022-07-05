table 80004 "PC Shopfiy Pricing"
{
    fields
    {
        field(10;"Item No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Item where(Type=Const(Inventory));       
        }
       
        field(15;Description; Text[100])
        {
            NotBlank = true;
            FieldClass = FlowField;
            CalcFormula = Lookup(Item.Description WHERE ("No."=FIELD("Item No.")));
        }
        field(20;"RRP Price"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Lookup(Item."Unit Price" WHERE ("No."= FIELD("Item No.")));
            Editable = false;
        }
        field(30;"New RRP Price"; Decimal)
        {
            trigger OnValidate()
            Begin
                if ("Starting Date" > Today) And ("New RRP Price" < "Sell Price") then
                    Error('New RRP < Sell Price');
            end;        
         }
        field(40;"Sell Price";Decimal)
        {
            trigger OnValidate()
            begin
                CalcFields("RRP Price");
                If ("Ending Date" = 0D) AND ("RRP Price" < "Sell Price") Then
                    Error('RRP < Sell Price')
            end;
        }
        field(50;"Platinum Member Disc %";Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
            trigger OnValidate()
            begin
                If "Platinum Member Disc %" < "Gold Member Disc %" then
                    Error('Platinum Member Disc % < Gold Member Disc %')
            end;
        }

        field(60;"Gold Member Disc %";Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
            trigger OnValidate()
            begin
                If "Gold Member Disc %" < "Silver Member Disc %" then
                    Error('Gold Member Disc % < Silver Member Disc %')
            end;
        }
        field(70;"Silver Member Disc %";Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
        }
        field(80;"Auto Order Disc %";Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
        }
        field(90;"VIP Disc %";Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
        }
        field(100;"Platinum + Auto Disc %";Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
            trigger OnValidate()
            begin
                If "Platinum + Auto Disc %" < "Gold + Auto Disc %" then
                    Error('Platinum + Auto Disc % < Gold + Auto Disc %')
            end;
          }
        field(110;"Gold + Auto Disc %";Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
        }
 
        field(150;"Starting Date"; date)
        {
            trigger OnValidate()
            begin
               If ("Ending Date" <> 0D) and ("Starting Date" > "Ending Date") then
                    error('Invalid Starting Date');
            end;
        }
        field(160;"Ending Date"; date)
        {
            trigger OnValidate()
            begin 
               if ("Starting Date" <> 0D) and ("Ending Date" <> 0D) AND ("Starting Date" > "Ending Date") then
                    error('Invalid Ending Date');
            end;        
        }
    }
    keys
    {
        key(PK; "Item No.","Starting Date")
        {
            Clustered = true;
        }
    }
    trigger OnInsert() 
    begin
        CalcFields("RRP Price");
        if "Starting Date" = 0D then
            Error(StrSubstNo('Starting Date Must be defined for Item %1',Rec."Item No."))
        else If ("Ending Date" = 0D) AND ("RRP Price" < "Sell Price") Then
            Error(strsubstno('RRP < Sell Price for Item %1',Rec."Item No."))
        else if ("Starting Date" > Today) And ("New RRP Price" < "Sell Price") then
            Error(strsubStno('New RRP < Sell Price for Item %1',Rec."Item No."))    
        else If "Platinum Member Disc %" < "Gold Member Disc %" then
            Error(strsubstno('Platinum Member Disc % < Gold Member Disc % for Item %1',Rec."Item No."))
        else If "Gold Member Disc %" < "Silver Member Disc %" then
            Error(StrSubstNo('Gold Member Disc % < Silver Member Disc % for Item %1',rec."Item No."))
        else If "Platinum + Auto Disc %" < "Gold + Auto Disc %" then
            Error(StrSubstNo('Platinum + Auto Disc % < Gold + Auto Disc % for Item %1',rec."Item No."));
            
    end;  
    trigger OnModify()
    begin
        CalcFields("RRP Price");
        if "Starting Date" = 0D then
            Error(StrSubstNo('Starting Date Must be defined for Item %1',Rec."Item No."))
        else If ("Ending Date" = 0D) AND ("RRP Price" < "Sell Price") Then
            Error(strsubstno('RRP < Sell Price for Item %1',Rec."Item No."))
        else if ("Starting Date" > Today) And ("New RRP Price" < "Sell Price") then
            Error(strsubStno('New RRP < Sell Price for Item %1',Rec."Item No."))    
        else If "Platinum Member Disc %" < "Gold Member Disc %" then
            Error(strsubstno('Platinum Member Disc % < Gold Member Disc % for Item %1',Rec."Item No."))
        else If "Gold Member Disc %" < "Silver Member Disc %" then
            Error(StrSubstNo('Gold Member Disc % < Silver Member Disc % for Item %1',rec."Item No."))
        else If "Platinum + Auto Disc %" < "Gold + Auto Disc %" then
            Error(StrSubstNo('Platinum + Auto Disc % < Gold + Auto Disc % for Item %1',rec."Item No."));
     end;
    trigger OnRename()
    begin
        Error('Rename is Invalid'); 
    end;
       
}