<%@ WebHandler Language="C#" Class="flpm_jczl_gc_userID" %>

using System;
using System.Web;
using System.IO;
using System.Data;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Converters;
using SAP.Middleware.Connector;
using System.Configuration;

public class flpm_jczl_gc_userID : IHttpHandler
{
    string model, jsonString, sql, sqlconOA = AF.sqlconOA, sqlconnOMS = AF.sqlconnOMS, errMsg, open, sqlconnSAP = AF.sqlconnSAP,sqlconnSapSystem = AF.sqlconnSapSystem;
    string userLog = "", userName = "", deptID = "", deptName = "", isuse = "", sqlconn="";
    int Count;
    System.Data.DataTable dt;
    Dictionary<string, object> header = new Dictionary<string, object>();
    JavaScriptSerializer jss = new JavaScriptSerializer();

    public void ProcessRequest(HttpContext context)
    {
        context.Response.Clear();
        context.Response.ContentType = "application/json";

        model = context.Request["model"];
        userLog = Cookie.GetValue("login");
        open = Cookie.GetValue("open");

        if (string.IsNullOrEmpty(userLog))
        {
            header["msg"] = "���󣺻�ȡ��½�û�ʧ�ܣ������µ�½��";
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }

        sql = "select a.isuse,a.userName,a.deptID,a.deptName,a.company_FK,a.companyName from sys_userInf a where ISNULL(a.isuse,'N')='Y' and a.userID='" + userLog + "'";

        if (!AF.execSql(sql, sqlconOA, out dt, out errMsg))
        {
            header["msg"] = "���󣺻�ȡ��½�û���Ϣʧ�ܣ�"+errMsg.ToString();
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }

        if (dt.Rows.Count == 0)
        {
            header["msg"] = "�����û�['" + userLog + "']��ͣ�û����ڲ��Ų����ڣ��޷�����ϵͳ��";
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }

        if (dt.Rows.Count > 0)
        {
            isuse = dt.Rows[0]["isuse"].ToString();
            userName = dt.Rows[0]["userName"].ToString();
            deptID = dt.Rows[0]["deptID"].ToString();
            deptName = dt.Rows[0]["deptName"].ToString();

            if (isuse == "N")
            {
                header["msg"] = "��������ְ����ͣ�ã���ֹ�������ݣ�";
                header["code"] = 1;
                jsonString = jss.Serialize(header);
                context.Response.Write(jsonString);
                return;
            }
        }

        //�����¼ѡ��Ĺ�˾��ͬ�������ӵ����ݿⲻ��
        sql = "select * from JOBCompany where Isuse='Y' and CompanyID='" + open + "'";
        if (!AF.execSql(sql, sqlconnOMS, out dt, out errMsg))
        {
            header["msg"] = "���󣺻�ȡ��˾��Ϣʧ�ܣ�" + errMsg.ToString();
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }

        if (dt.Rows.Count == 0)
        {
            header["msg"] = "���󣺹�˾['" + open + "']δ���ñ���ϵͳ������ϵ����Ա��";
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }
        sqlconn = dt.Rows[0]["SqlConn"].ToString();
        sqlconn = ConfigurationManager.ConnectionStrings[sqlconn].ConnectionString;


        if (model == "xxx")
        {
            //TODO
            return;
        }




    }


    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

    public static DataTable JArrayToDatable(JArray dataArr)
    {
        if (dataArr == null || dataArr.Count <= 0) return null;

        DataTable result = new DataTable();
        var colnames = ((JObject)dataArr.First).Properties();
        List<string> columnNames = new List<string>();

        if (colnames == null) return null;

        foreach (var item in colnames)
        {
            if (!columnNames.Contains(item.Name))
            {
                columnNames.Add(item.Name);
            }
            result.Columns.Add(item.Name, typeof(string));
        }
        foreach (JObject data in dataArr)
        {
            JObject jo = JObject.Parse(data.ToString());
            DataRow row = result.NewRow();
            foreach (var columnName in columnNames)
            {
                if (jo.Property(columnName) == null)
                {
                    data.Add(columnName, "");
                    row[columnName] = data[columnName].ToString();
                }
                else
                {
                    row[columnName] = data[columnName].ToString();
                }
            }
            result.Rows.Add(row);
        }
        return result;
    }
}