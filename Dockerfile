FROM registry.access.redhat.com/ubi8/go-toolset:1.16.12 as builder
ENV GOPATH=$APP_ROOT
COPY --chown=1001:0 . .
RUN make cmd

FROM registry.access.redhat.com/ubi8/python-38

USER 0

RUN git clone https://github.com/konveyor/tackle-container-advisor.git /app

WORKDIR /app

RUN  bash setup.sh; \
     python -m pip install --upgrade pip wheel build setuptools; \
     pip install -r entity_standardizer/requirements.txt; \
     cd entity_standardizer; python -m build; pip install dist/entity_standardizer_tca-1.0-py3-none-any.whl; cd ..; \
     pip install -r /app/requirements.txt; \
     python benchmarks/generate_data.py; \
     python benchmarks/run_models.py;

RUN chown -R 1001:0 ./

USER 1001

ENV PORT 8000
EXPOSE $PORT


COPY --from=builder /opt/app-root/src/bin/addon /usr/local/bin/addon
ENTRYPOINT ["/usr/local/bin/addon"]

#ENV GUNICORN_BIND 0.0.0.0:$PORT
#CMD ["gunicorn", "-c", "config/gunicorn.py", "service:app"]
