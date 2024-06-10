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
    /// <summary>
    /// model 相当于调用方法；
    /// jsonString 格式转换
    /// sql 拼接sql语句
    /// errMsg 错误消息
    /// open 公司ID
    /// </summary>
    string model, jsonString, sql, errMsg, open;

    /// <summary>
    /// 查询数据库记录的条数
    /// </summary>
    int Count;

    /// <summary>
    /// 设置不同数据库的连接
    /// </summary>
    string sqlconOA = AF.sqlconOA,
           sqlconnOMS = AF.sqlconnOMS,
           sqlconnSAP = AF.sqlconnSAP,
           sqlconnSapSystem = AF.sqlconnSapSystem;

    // TODO
    /// <summary>
    /// userLog 
    /// userName 用户名
    /// deptID 部门ID
    /// deptName 部门名称
    /// isuse 是否使用中
    /// sqlconn 数据库链接
    /// </summary>
    string userLog = "", userName = "", deptID = "", deptName = "", isuse = "", sqlconn="";

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
            header["msg"] = "错误：获取登陆用户失败，请重新登陆！";
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }

        sql = "select a.isuse,a.userName,a.deptID,a.deptName,a.company_FK,a.companyName from sys_userInf a where ISNULL(a.isuse,'N')='Y' and a.userID='" + userLog + "'";

        if (!AF.execSql(sql, sqlconOA, out dt, out errMsg))
        {
            header["msg"] = "错误：获取登陆用户信息失败！"+errMsg.ToString();
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }

        if (dt.Rows.Count == 0)
        {
            header["msg"] = "错误：用户['" + userLog + "']已停用或所在部门不存在，无法操作系统！";
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
                header["msg"] = "错误：已离职或已停用，禁止操作数据！";
                header["code"] = 1;
                jsonString = jss.Serialize(header);
                context.Response.Write(jsonString);
                return;
            }
        }

        //如果登录选择的公司不同，则连接的数据库不对
        sql = "select * from JOBCompany where Isuse='Y' and CompanyID='" + open + "'";
        if (!AF.execSql(sql, sqlconnOMS, out dt, out errMsg))
        {
            header["msg"] = "错误：获取公司信息失败！" + errMsg.ToString();
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }

        if (dt.Rows.Count == 0)
        {
            header["msg"] = "错误：公司['" + open + "']未配置报工系统，请联系管理员！";
            header["code"] = 1;
            jsonString = jss.Serialize(header);
            context.Response.Write(jsonString);
            return;
        }
        sqlconn = dt.Rows[0]["SqlConn"].ToString();
        sqlconn = ConfigurationManager.ConnectionStrings[sqlconn].ConnectionString;

        /// <summary>
        /// 1. 定义前端传过来的数据；
        /// 2. 拼接sql；
        /// 3. 清空dt；
        /// 4. 判断执行结果并转换格式，返回。
        /// </summary>
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