### All users anbd their groups
```
MATCH p=(u:User)-[:MemberOf*1..]->(:Group) RETURN p
```