pageextension 80020 "PC Assembly Bom Ext" extends "Assembly BOM" 
{
    layout
    {
        addafter("Unit of Measure Code")
        {
            field("Bundle Price Value %"; Rec."Bundle Price Value %")
            {
                ApplicationArea = All;
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if rec.Count > 0 then
        begin
            Rec.CalcSums("Bundle Price Value %");
            If Rec."Bundle Price Value %" < 100 then
                error('Bundle Price Values % must sum to 100 .. Correct')
        end;        
    end;
}