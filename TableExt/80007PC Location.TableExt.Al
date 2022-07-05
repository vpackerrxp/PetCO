tableextension 80007 "PC Locations Ext" extends Location
{
    fields
    {
        field(80000; "Fulfilo Warehouse ID"; option)
        {
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10","11","12";
            trigger OnValidate()
            begin
                case "Fulfilo Warehouse ID" of
                    0:Clear("Fulfilo Warehouse Description");
                    1:"Fulfilo Warehouse Description" := 'Melbourne Warehouse TEST';
                    2:"Fulfilo Warehouse Description" := '';
                    3:"Fulfilo Warehouse Description" := 'Melbourne Warehouse';
                    4:"Fulfilo Warehouse Description" := 'Sydney Warehouse';
                    5:"Fulfilo Warehouse Description" := 'Perth Warehouse,';
                    6:"Fulfilo Warehouse Description" := 'Brisbane Warehouse';
                    7:"Fulfilo Warehouse Description" := 'Sydney Warehouse TEST';
                    8:"Fulfilo Warehouse Description" := 'Perth Warehouse TEST';
                    9:"Fulfilo Warehouse Description" := 'Brisbane Warehouse TEST';
                    10:"Fulfilo Warehouse Description" := '';
                    11:"Fulfilo Warehouse Description" := '';
                    12:"Fulfilo Warehouse Description" := '';
                end;      
            end;
        }
        
        field(80001; "Fulfilo Warehouse Description"; Text[50])
        {
            Editable = false;     
        }
    }
    
}