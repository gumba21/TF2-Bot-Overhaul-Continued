#if defined _tf2_flag_included
 #endinput
#endif
#define _tf2_flag_included

/** Returns true when the client currently owns an item_teamflag entity. */
stock bool TF2_HasTheFlag(int client)
{
    int flag = -1;
    while ((flag = FindEntityByClassname(flag, "item_teamflag")) != -1)
    {
        if (GetEntPropEnt(flag, Prop_Send, "m_hOwnerEntity") == client)
        {
            return true;
        }
    }
    return false;
}
