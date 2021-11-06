import React, { useState, useEffect } from "react";
import queryString from 'query-string'
import {
    BrowserRouter as Router,
    Switch,
    Route,
    Redirect,
    useLocation,
    Link
  } from "react-router-dom";
import { Button, Navbar, Nav, Form, Col, InputGroup, Row, FormControl, Container,Table } from 'react-bootstrap'
import logo from './../logo.svg';

function CitedResult(props) {
    const { search } = useLocation()
    const urlparams = queryString.parse(search)
    const [init, setinit] = useState(false)
    const [query, setQuery] = useState("")
    const [data, setData] = useState([])
    const [originPaper, setOrigin] = useState(null)


    useEffect(() => {
        console.log(urlparams.query)
        if(urlparams.query){
            GetPaperByEid(urlparams.query)
            PostTest(urlparams.query)
            setQuery(urlparams.query)
        }
    },[init]);

    async function PostTest(keyword) {
        if(!keyword){
            alert("query con not be null!")
            return
        }
        const requestOptions = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ keyword: keyword })
        };
        props.setLoading(true)
        try {
            fetch('http://localhost:9292/project', requestOptions)
                .then(async response => {
                    let result = await response.json()
                    // console.log(result)
                    setData(result)
                    props.setLoading(false)
                })
        } catch (e) {
            console.log(e.message)
        }

    }

    async function GetTest() {
        var result = await fetch('http://localhost:9292/project/www/qqq');
        var content = await result.text()
        console.log(content)
    }

    async function Search() {
        console.log(query)
    }

    function reloadnewurl(url,eid){
        setQuery(eid)
        PostTest(eid)
    }

    async function GetPaperByEid(keyword) {
        if(!keyword){
            alert("query con not be null!")
            return
        }
        const requestOptions = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ eid: keyword })
        };
        props.setLoading(true)
        try {
            fetch('http://localhost:9292/db/eid', requestOptions)
                .then(async response => {
                    let result = await response.json()
                    setOrigin(result)
                    console.log(result)
                    props.setLoading(false)
                })
        } catch (e) {
            console.log(e.message)
        }
    }

    return (
        <>
            <br />
            <div className="App">
                <h1>Cited Papers of</h1>
            </div>
            <br />
            <Container>
                <Row>
                    <Col></Col>
                    <Col xs={10}>
                        <h2><a href={originPaper.paper_link} target="_blank">{originPaper.title}</a></h2>
                    </Col>
                    <Col></Col>

                </Row>
                <Row>
                    <Table striped bordered hover size="sm" style={{ width: '85%', margin: "auto", marginTop: "1%"}}>
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Title</th>
                                <th>Lead Author</th>
                                <th>Organization</th>
                                <th>Paper Link</th>
                                <th>Citedby</th>
                            </tr>
                        </thead>
                        <tbody >
                            {data.map((self, index) => <tr key={index}>
                                <td width="3%">{index}</td>
                                {/* name */}
                                <td>{self.title}</td>
                                {/* type */}
                                <td width="15%">{self.author}</td>
                                <td width="15%" overflow="hidden">{self.organization}</td>
                                <td width="10%"><a href={self.paper_link} target="_blank">Scopus link</a></td>
                                {/* <td width="10%">{self.citedby}<br/><a href={self.citedby_link} target="_blank">Detail</a></td> */}
                                <td width="10%"><Link to={`/citedResult/?query=ref(${self.eid})`} onClick={()=>{reloadnewurl(`/citedResult/?query=ref(${self.eid})`,`ref(${self.eid})`)}}>{self.citedby}</Link></td>
                            </tr>)}
                        </tbody>
                    </Table>
                </Row>
            </Container>
        </>
    );
}

export default CitedResult;
